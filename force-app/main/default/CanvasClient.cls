public with sharing class CanvasClient {

    @future(callout=true)
    public static void syncCanvasCourse(Id canvasCourseRecordId) {
        CanvasCourse__c c = [SELECT Id, Name, Title__c, CanvasCourseId__c, Start_Date__c, End_Date__c, CanvasSubAccountId__c, BlueprintCanvasCourseId__c, Term__c FROM CanvasCourse__c WHERE ID = :canvasCourseRecordId LIMIT 1];        
                
        Integer canvas_course_id;

        Canvas_Settings__c settings = Canvas_Settings__c.getInstance();        
        Integer sub_account_id = (Integer) settings.sub_account_id__c;

        Http http = new Http();

        // try to get an existing course first
        String canvasCourseIdParam;
        if (c.CanvasCourseId__c != null) {
            canvasCourseIdParam = String.valueOf(c.CanvasCourseId__c);
        } else {
            canvasCourseIdParam = 'sis_course_id:' + c.Id;
        }
        String blueprintCanvasCourseIdParam;

        HttpRequest req = prepareRequest('courses/' + canvasCourseIdParam, 'GET', settings, false);
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            // the course exists in Canvas; update it 
            HttpRequest upd_req = prepareRequest('courses/' + canvasCourseIdParam, 'PUT', settings, false);
            String courseJson = courseToJson(c);
            upd_req.setBody(courseJson);
            HTTPResponse upd_res = http.send(upd_req);
            c = jsonToCourse(upd_res.getBody(), c);
            //update blueprint course subscription if it exists.
            if (c.BlueprintCanvasCourseId__c != null) {
                subscribeToBlueprintCourse(c.Id, c.BlueprintCanvasCourseId__c, c.CanvasCourseId__c);
            } else{
                //TODO:check if existing blue print subscription should be unsubscribed?
            }
            //Note: The DB update needs to happen after the api call. SF complains about uncommited transaction otherwise
            update c;
            CanvasHelper.ActivityLogGenerate('DEBUG', 'Updated Canvas Course: '+c, 'CanvasClient.syncCanvasCourse', c.Id, null, null);
        } else if (res.getStatusCode() == 404) {
            // the course doesn't exist in Canvas; create it
            HttpRequest new_course_req = prepareRequest('accounts/' + c.CanvasSubAccountId__c + '/courses', 'POST', settings, false);
            new_course_req.setBody(courseToJson(c));
            HTTPResponse new_course_res = http.send(new_course_req);
            
            if (new_course_res.getStatusCode() == 200 || Test.isRunningTest()) {
                CanvasCourse__c updatedCourse = jsonToCourse(new_course_res.getBody(), c);
                //update blueprint course if subscription  exists
                if (c.BlueprintCanvasCourseId__c != null) {
                    subscribeToBlueprintCourse(c.Id, c.BlueprintCanvasCourseId__c, updatedCourse.CanvasCourseId__c);
                }
                //Note: The DB update needs to happen after the api call. SF complains about uncommited transaction otherwise
                update updatedCourse;
                CanvasHelper.ActivityLogGenerate('DEBUG', 'Created Canvas Course: '+updatedCourse, 'CanvasClient.syncCanvasCourse', c.Id, null, null);
            } else {
                String errorStr =  'syncCanvasCourse '+ '\n' + new_course_res.getBody() + '\n'+  new_course_res.toString(); 
                System.debug(errorStr); 
                CanvasHelper.ActivityLogGenerate('ERROR', errorStr, 'CanvasClient.syncCanvasCourse', c.Id, null, null);
            }    
        }
    }

    @future(callout=true)
    public static void syncCanvasUser(Id canvasUserRecordId) {
        CanvasUser__c u = [SELECT Id, CanvasUserId__c, Fullname__c, Email__c  FROM CanvasUser__c WHERE Id = :canvasUserRecordId LIMIT 1];   
        Canvas_Settings__c settings = Canvas_Settings__c.getInstance();
    
        Http http = new Http();

        // if our CanvasUser object already has a CanvasUserId__c value, assume that the user already exists
        // otherwise, search for an existing user
        if (u.CanvasUserId__c != null) {
            System.debug('updating an existing Canvas user by id: ' + u.CanvasUserId__c);
            // update the name and email, as user is already present
            HttpRequest update_user_req = prepareRequest('users/'+ u.CanvasUserId__c, 'PUT', settings, true);
            update_user_req.setBody(userToJsonForUpdate(u));
            HTTPResponse update_user_res = http.send(update_user_req);      
            if (update_user_res.getStatusCode() == 200) {
                CanvasUser__c updatedUser = jsonToUser(update_user_res.getBody(), u);
                System.debug('successfully updated user'+updatedUser);
                CanvasHelper.ActivityLogGenerate('DEBUG', 'successfully updated user:'+updatedUser, 'CanvasClient.syncCanvasUser', null, null, u.Id);

            } else {
                System.debug('got a non-200 response from the update/edit user call: '+ update_user_res.getStatusCode());
                String errorStr =  'syncCanvasUser '+ '\n' + update_user_res.getBody() + '\n'+  update_user_req.toString(); 
                System.debug(errorStr); 
                CanvasHelper.ActivityLogGenerate('ERROR', errorStr, 'CanvasClient.syncCanvasUser', null, null, u.Id);
            } 
        }
        else {
            // First, search for an existing user with this email address
            String search_term = EncodingUtil.urlEncode(u.Email__c, 'UTF-8');
            HttpRequest find_user_req = prepareRequest('accounts/1/users?search_term='+search_term, 'GET', settings, true);
            Map<String, String> params = new Map<String, String>();
            params.put('search_term', u.Email__c);
            HTTPResponse find_user_res = http.send(find_user_req);

            if (find_user_res.getStatusCode() == 200) {
                String jsonText = find_user_res.getBody();
                List<Object> users = (List<Object>) JSON.deserializeUntyped(jsonText);     
                if (users.size() == 1) {
                    // If we found an existing user, update our CanvasUser record with the Canvas user ID and confirmation URL
                    String userJsonText = JSON.serialize(users.get(0));
                    Map<String, Object> user = (Map<String, Object>) JSON.deserializeUntyped(userJsonText); 
                    Integer canvas_user_id = (Integer)user.get('id');
                    System.debug('Search for ' + u.Email__c + ' returned ' + canvas_user_id);
                    u.CanvasUserId__c = canvas_user_id;
                    update u;
                    CanvasHelper.ActivityLogGenerate('DEBUG', 'Updated existing user:'+u, 'CanvasClient.syncCanvasUser', null, null, u.Id);
                    return;
                } else if (users.size() == 0) {
                    // Found no users, so we need to create one
                    HttpRequest new_user_req = prepareRequest('accounts/1/users', 'POST', settings, true);
                    new_user_req.setBody(userToJson(u));
                    HTTPResponse new_user_res = http.send(new_user_req);
                    
                    if (new_user_res.getStatusCode() == 200) {
                        CanvasUser__c updatedUser = jsonToUser(new_user_res.getBody(), u);
                        System.debug(updatedUser);
                        update updatedUser;
                        CanvasHelper.ActivityLogGenerate('DEBUG', 'Created new user:'+updatedUser, 'CanvasClient.syncCanvasUser', null, null, u.Id);

                    } else {
                        System.debug('got a non-200 response from the create user call: '+ new_user_res.getStatusCode());
                        String errorStr =  'syncCanvasUser '+ '\n' + new_user_res.getBody() + '\n'+  new_user_res.toString();
                        System.debug(errorStr);  
                        CanvasHelper.ActivityLogGenerate('ERROR', errorStr, 'CanvasClient.syncCanvasUser', null, null, u.Id);
                    }                
                } else {
                    // Found more than one matching user; bail
                    String errorStr =  'Search for ' + contact.Email + ' returned ' + users.size() +' results';  
                    System.debug(errorStr);                       
                    CanvasHelper.ActivityLogGenerate('ERROR', errorStr, 'CanvasClient.syncCanvasUser', null, null, u.Id);
                    return;
                }
            } else {
                String errorStr =  'searching for a user returned a non-200 response'; 
                System.debug(errorStr);                        
                CanvasHelper.ActivityLogGenerate('ERROR', errorStr, 'CanvasClient.syncCanvasUser', null, null, u.Id);
            }
        }
    }

    @future(callout=true)
    public static void syncEnrollmentToCanvas(Id canvasEnrollmentId, String requestType) {

        // Get the Canvas settings that will be used in our request 
        Canvas_Settings__c settings = Canvas_Settings__c.getInstance();

        HttpRequest enrlReq;
        CanvasEnrollment__c ce;

        // Build the appropriate type of request based off of what we are trying to, delete an enrollment or create/update
        if(requestType=='delete') {
            ce = [SELECT Id, CanvasEnrollmentId__c, CanvasCourse__c, CanvasCourse__r.CanvasCourseId__c, CanvasUser__c, CanvasUser__r.CanvasUserId__c, Status__c from CanvasEnrollment__c where Id = :canvasEnrollmentId];
            enrlReq = prepareRequest('courses/'+ ce.CanvasCourse__r.CanvasCourseId__c +'/enrollments/'+ce.CanvasEnrollmentId__c, 'DELETE', settings, false);
            Map<String, String> bodyMap = new Map<String, String>();
            bodyMap.put('task', 'delete');
            String jsonEnrollmentBody = JSON.serializePretty(bodyMap, true);
            enrlReq.setBody(jsonEnrollmentBody);
        } else {
            ce = [SELECT Id, CanvasEnrollmentId__c, CanvasCourse__r.CanvasCourseId__c, CanvasUser__r.CanvasUserId__c, Status__c from CanvasEnrollment__c where Id = :canvasEnrollmentId];
            enrlReq = prepareRequest('courses/'+ ce.CanvasCourse__r.CanvasCourseId__c +'/enrollments', 'POST', settings, false);
            enrlReq.setBody(enrollmentToJson(ce));
        }

        Http http = new Http();
        HTTPResponse enrlRes = http.send(enrlReq);

        if (enrlRes.getStatusCode() == 200) {
            String enrlJsonText = enrlRes.getBody();
            ce = jsonToEnrollment(enrlJsonText, ce);
            CanvasHelper.ActivityLogGenerate('DEBUG', 'Successfully performed a '+ requestType +' on user enrollment : '+ce+' in course:'+ce.CanvasCourse__r.CanvasCourseId__c, 'CanvasClient.syncEnrollmentToCanvas', ce.CanvasCourse__c, ce.Id, ce.CanvasUser__c);
            if(requestType == 'delete') {
                ce.CanvasEnrollmentId__c = null;
            }
            update ce;
        } else {
            System.debug('got a non-200 response when enrolling  user: '+ enrlRes.getStatusCode());
            System.debug(enrlRes.toString());
            String errorStr =  'syncEnrollmentToCanvas '+ '\n' + enrlRes.getBody() + '\n'+  enrlRes.toString(); 
            CanvasHelper.ActivityLogGenerate('ERROR', errorStr, 'CanvasClient.syncEnrollmentToCanvas', ce.CanvasCourse__c, ce.Id, ce.CanvasUser__c);
        }
    }

    @TestVisible
    private static void  subscribeToBlueprintCourse(Id courseId, Decimal BlueprintCanvasCourseId, Decimal currentCanvasCourseId){
        try{
            Http http = new Http();
            Canvas_Settings__c settings = Canvas_Settings__c.getInstance(); 
            String bpCanvasCourseIdParam = String.valueOf(BlueprintCanvasCourseId);
            String currentCanvasCourseIdParam = String.valueOf(currentCanvasCourseId);

            HttpRequest upd_req = prepareRequest('courses/' + bpCanvasCourseIdParam +'/blueprint_templates/default/update_associations?course_ids_to_add[]='+currentCanvasCourseIdParam, 'PUT', settings, false);
            HTTPResponse upd_res = http.send(upd_req);
            if (upd_res.getStatusCode() == 200){
                CanvasHelper.ActivityLogGenerate('DEBUG', 'Updated Blueprint subscription to  :'+BlueprintCanvasCourseId+' for course:'+currentCanvasCourseId, 'CanvasClient.subscribeToBlueprintCourse', courseId, null, null);
            } else{
                //If the Blueprint subscription fails, try once more after a 2 second wait(We are noticing some 400s when a Blueprint 
                //subscription happens soon after course creation)
                Long milliSeconds = 2000;
                Long timeDiff = 0;
                DateTime firstTime = System.now();
                do{
                    timeDiff = System.now().getTime() - firstTime.getTime();
                }
                while(timeDiff <= milliSeconds);
               
                upd_res = http.send(upd_req);
                if (upd_res.getStatusCode() == 200){
                    CanvasHelper.ActivityLogGenerate('DEBUG', 'Updated Blueprint subscription to(2nd attempt)  :'+BlueprintCanvasCourseId+' for course:'+currentCanvasCourseId, 'CanvasClient.subscribeToBlueprintCourse', courseId, null, null);
                } else{
                    System.debug('got another non-200 response in blueprint subscription'+upd_res.toString());
                    CanvasHelper.ActivityLogGenerate('ERROR', 'Repeated error in blueprint subscription for course:'+currentCanvasCourseId+',error='+upd_res.toString(), 'CanvasClient.subscribeToBlueprintCourse', courseId, null, null);
                }
                
            }
        }catch(Exception ex){
            System.debug('The following exception has occurred in subscribeToBlueprintCourse: ' + ex.getMessage());
            CanvasHelper.ActivityLogGenerate('ERROR', 'Error in blueprint subscription for course:'+currentCanvasCourseId+
            ',Exception:'+ex.getMessage() , 'CanvasClient.subscribeToBlueprintCourse', courseId, null, null);
        }
        
    }

    @TestVisible
    private static String courseToJson(CanvasCourse__c canvasCourse) {
        // given a CanvasCourse sObject, return a JSON string that can be passed to the Canvas create/update course API call
        Map<String, Object> innerMap = new Map<String, Object>();
        System.debug('user TZ: ' +UserInfo.getTimeZone().getDisplayName());
        innerMap.put('name', canvasCourse.Title__c);
        innerMap.put('course_code', canvasCourse.Name);
        innerMap.put('sis_course_id', canvasCourse.Id);
        innerMap.put('account_id', canvasCourse.CanvasSubAccountId__c);
        innerMap.put('start_at', canvasCourse.Start_Date__c);
        innerMap.put('end_at', canvasCourse.End_Date__c);
        innerMap.put('term_id', canvasCourse.Term__c);
        Map<String, Object> outerMap = new Map<String, Object>();
        outerMap.put('course', innerMap);
        String jsonCourse = JSON.serializePretty(outerMap, true);
        return jsonCourse;
    }

    @TestVisible
    private static CanvasCourse__c jsonToCourse(String jsonCourse, CanvasCourse__c canvasCourse) {
        // update a CanvasCourse__c object with some values from a JSON response 
        Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(jsonCourse);

        canvasCourse.CanvasCourseId__c = (Integer) objMap.get('id');

        // should updates from the Canvas side be reflected in Salesforce?

        return canvasCourse;
    }

    @TestVisible
    private static String userToJson(CanvasUser__c canvasUser) {
        // given a CanvasUser sObject, return a JSON string that can be passed to the Canvas create/update user API call
        Map<String, Object> userMap = new Map<String, Object>();        
        userMap.put('name', canvasUser.Fullname__c);
        userMap.put('skip_registration', 'false');

        Map<String, Object> pseudonymMap = new Map<String, Object>();
        pseudonymMap.put('unique_id', canvasUser.Email__c);
        pseudonymMap.put('send_confirmation', 'false');

        Map<String, Object> communicationChannelMap = new Map<String, Object>();
        communicationChannelMap.put('confirmation_url', 'true');
        communicationChannelMap.put('type', 'email');
        communicationChannelMap.put('address', canvasUser.Email__c);

        Map<String, Object> outerMap = new Map<String, Object>();
        outerMap.put('user', userMap);
        outerMap.put('pseudonym', pseudonymMap);
        outerMap.put('communication_channel', communicationChannelMap);
        String jsonUser = JSON.serializePretty(outerMap, true);

        return jsonUser;
    }

    @TestVisible
    private static String userToJsonForUpdate(CanvasUser__c canvasUser) {
        // given a CanvasUser sObject, return a JSON string that can be passed to the Canvas update user API call. 
        // Note that the json format is different for update/edit
        
        Map<String, Object> userMap = new Map<String, Object>();
        userMap.put('name', canvasUser.Fullname__c);
        userMap.put('email', canvasUser.Email__c);
       
        Map<String, Object> outerMap = new Map<String, Object>();
        outerMap.put('user', userMap);
        String jsonUser = JSON.serializePretty(outerMap, true);
        return jsonUser;
    }

    @TestVisible
    private static CanvasUser__c jsonToUser(String jsonUser, CanvasUser__c canvasUser) {
        // update a CanvasUser__c object with some values from a JSON response 
        Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(jsonUser);
        
        canvasUser.CanvasUserId__c = (Integer) objMap.get('id');
        canvasUser.ConfirmationUrl__c = (String) objMap.get('confirmation_url');

        return canvasUser; 
    }

    @TestVisible
    private static String enrollmentToJson(CanvasEnrollment__c canvasEnrollment) {
        Map<String, String> innerMap = new Map<String, String>();
        innerMap.put('user_id', String.valueOf(canvasEnrollment.CanvasUser__r.CanvasUserId__c));
        innerMap.put('enrollment_state', 'active');
        innerMap.put('type', 'StudentEnrollment');
        Map<String, Object> outerMap = new Map<String, Object>();
        outerMap.put('enrollment', innerMap);

        String jsonEnrollment = JSON.serializePretty(outerMap, true);
        return jsonEnrollment;
    }

    @TestVisible
    private static CanvasEnrollment__c jsonToEnrollment(String jsonEnrollment, CanvasEnrollment__c canvasEnrollment) {
        Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(jsonEnrollment);
        if (objMap.get('enrollment_status') == 'active') {
            canvasEnrollment.Status__c = 'Active';
        }
        canvasEnrollment.CanvasEnrollmentId__c = (Integer) objMap.get('id');
        return canvasEnrollment;
    }

    @TestVisible
    private static HttpRequest prepareRequest(String path, String method, Canvas_Settings__c settings, Boolean useGateway) {
        // get the settings that we'll need 
        String token = settings.token__c;
        System.debug('token: ' + token);
        String base_url;
        if (useGateway) {
            base_url = settings.ApiGatewayBaseUrl__c;
        } else {
            base_url = settings.base_url__c;
        }
        String api_base = base_url + 'api/v1/';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(api_base + path);
        System.debug('API REQUEST: ' + method + ' ' + api_base + path);
        if (useGateway) {
            req.setHeader('x-api-key', settings.ApiGatewayKey__c);
        } else {
            req.setHeader('Authorization', 'Bearer ' + token);
        }
        req.setMethod(method);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        return req;
    }

    /* 
    private static String formatApiBody(Map<String, String> params) {
        // this seems to be the least-gross way to build a URL query string or form-encoded POST body...
        System.PageReference tmpUrl = new System.PageReference('');
        tmpUrl.getParameters().putAll(params);
        // getUrl() produces a string that starts with '//?' so we need to rip that off
        return tmpUrl.getUrl().substringAfter('?');
    }
    */
}