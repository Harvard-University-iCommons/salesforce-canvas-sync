public with sharing class CanvasClient {

    @future(callout=true)
    public static void syncCanvasCourse(Id canvasCourseRecordId) {
        CanvasCourse__c c = [SELECT Id, Name, Title__c, CanvasCourseId__c FROM CanvasCourse__c WHERE ID = :canvasCourseRecordId LIMIT 1];        
        System.debug(c.Name);
                
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

        HttpRequest req = prepareRequest('courses/' + canvasCourseIdParam, 'GET', settings);
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            // the course exists in Canvas; update it 
            HttpRequest upd_req = prepareRequest('courses/' + canvasCourseIdParam, 'PUT', settings);
            String courseJson = courseToJson(c);
            upd_req.setBody(courseJson);
            HTTPResponse upd_res = http.send(upd_req);
            System.debug('update response: ' + upd_res.getStatusCode());
            c = jsonToCourse(upd_res.getBody(), c);
            update c;

        } else if (res.getStatusCode() == 404) {
            // the course doesn't exist in Canvas; create it
            HttpRequest new_course_req = prepareRequest('accounts/' + sub_account_id + '/courses', 'POST', settings);
            new_course_req.setBody(courseToJson(c));
            HTTPResponse new_course_res = http.send(new_course_req);
            
            if (new_course_res.getStatusCode() == 200) {
                CanvasCourse__c updatedCourse = jsonToCourse(new_course_res.getBody(), c);
                update updatedCourse;
            }       
        }
    }

    @future(callout=true)
    public static void syncCanvasUser(Id canvasUserRecordId) {
        CanvasUser__c u = [SELECT Id, CanvasUserId__c, Contact__r.Name, Contact__r.Email  FROM CanvasUser__c WHERE Id = :canvasUserRecordId LIMIT 1];        
        Contact contact = u.Contact__r; 
        Canvas_Settings__c settings = Canvas_Settings__c.getInstance();
    
        Http http = new Http();

        // if our CanvasUser object already has a CanvasUserId__c value, assume that the user already exists
        // otherwise, search for an existing user

        if (u.CanvasUserId__c != null) {
            System.debug('updating an existing Canvas user by id: ' + u.CanvasUserId__c);
            // TODO: update the name and email
        }
        else {
            // First, search for an existing user with this email address
            String search_term = EncodingUtil.urlEncode(u.Contact__r.Email, 'UTF-8');
            HttpRequest find_user_req = prepareRequest('accounts/1/users?search_term='+search_term, 'GET', settings);
            Map<String, String> params = new Map<String, String>();
            params.put('search_term', u.Contact__r.Email);
            HTTPResponse find_user_res = http.send(find_user_req);  

            if (find_user_res.getStatusCode() == 200) {
                String jsonText = find_user_res.getBody();
                List<Object> users = (List<Object>) JSON.deserializeUntyped(jsonText);     
                if (users.size() == 1) {
                    // If we found an existing user, update our CanvasUser record with the Canvas user ID and confirmation URL
                    String userJsonText = JSON.serialize(users.get(0));
                    Map<String, Object> user = (Map<String, Object>) JSON.deserializeUntyped(userJsonText); 
                    Integer canvas_user_id = (Integer)user.get('id');
                    System.debug('Search for ' + u.Contact__r.Email + ' returned ' + canvas_user_id);
                    u.CanvasUserId__c = canvas_user_id;
                    update u;
                    return;
                } else if (users.size() == 0) {
                    // Found no users, so we need to create one
                    HttpRequest new_user_req = prepareRequest('accounts/1/users', 'POST', settings);
                    new_user_req.setBody(userToJson(u));
                    HTTPResponse new_user_res = http.send(new_user_req);
                    
                    if (new_user_res.getStatusCode() == 200) {
                        CanvasUser__c updatedUser = jsonToUser(new_user_res.getBody(), u);
                        System.debug(updatedUser);
                        update updatedUser;
                    } else {
                        System.debug('got a non-200 response from the create user call: '+ new_user_res.getStatusCode());
                        System.debug(new_user_res.getBody());
                        System.debug(new_user_req.toString());
                    }                
                } else {
                    // Found more than one matching user; bail
                    System.debug('Search for ' + contact.Email + ' returned ' + users.size() +' results');
                    return;
                }
            } else {
                System.debug('searching for a user returned a non-200 response');
            }
        }
    }

    @future(callout=true)
    public static void syncEnrollmentToCanvas(Id canvasEnrollmentId) {

        // fetch the CanvasEnrollment__c record
        CanvasEnrollment__c ce = [SELECT Id, CanvasEnrollmentId__c, CanvasCourse__r.CanvasCourseId__c, CanvasUser__r.CanvasUserId__c, Status__c from CanvasEnrollment__c where Id = :canvasEnrollmentId];

        // now we've got a Canvas user and course ID; ready to create/update the enrollment record: 
        Canvas_Settings__c settings = Canvas_Settings__c.getInstance();
        
        HttpRequest new_enrl_req = prepareRequest('courses/'+ ce.CanvasCourse__r.CanvasCourseId__c +'/enrollments', 'POST', settings);
        new_enrl_req.setBody(enrollmentToJson(ce));
        Http http = new Http();
        HTTPResponse new_enrl_res = http.send(new_enrl_req);
        
        if (new_enrl_res.getStatusCode() == 200) {
            String newEnrlJsonText = new_enrl_res.getBody();
            ce = jsonToEnrollment(newEnrlJsonText, ce);
            update ce;
        } else {
            System.debug('Got a non-200 response when enrolling a user');
            // todo 
        }
    }

    private static String courseToJson(CanvasCourse__c canvasCourse) {
        // given a CanvasCourse sObject, return a JSON string that can be passed to the Canvas create/update course API call
        Map<String, Object> innerMap = new Map<String, Object>();

        innerMap.put('name', canvasCourse.Title__c);
        innerMap.put('course_code', canvasCourse.Name);
        innerMap.put('sis_course_id', canvasCourse.Id);

        Map<String, Object> outerMap = new Map<String, Object>();
        outerMap.put('course', innerMap);
        String jsonCourse = JSON.serializePretty(outerMap, true);

        return jsonCourse;
    }

    private static CanvasCourse__c jsonToCourse(String jsonCourse, CanvasCourse__c canvasCourse) {
        // update a CanvasCourse__c object with some values from a JSON response 
        Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(jsonCourse);

        canvasCourse.CanvasCourseId__c = (Integer) objMap.get('id');

        // should updates from the Canvas side be reflected in Salesforce?

        return canvasCourse;
    }

    private static String userToJson(CanvasUser__c canvasUser) {
        // given a CanvasUser sObject, return a JSON string that can be passed to the Canvas create/update user API call
        Map<String, Object> userMap = new Map<String, Object>();
        userMap.put('name', canvasUser.Contact__r.Name);
        userMap.put('skip_registration', 'false');

        Map<String, Object> pseudonymMap = new Map<String, Object>();
        pseudonymMap.put('unique_id', canvasUser.Contact__r.Email);
        pseudonymMap.put('send_confirmation', 'false');

        Map<String, Object> communicationChannelMap = new Map<String, Object>();
        communicationChannelMap.put('confirmation_url', 'true');
        communicationChannelMap.put('type', 'email');
        communicationChannelMap.put('address', canvasUser.Contact__r.Email);

        Map<String, Object> outerMap = new Map<String, Object>();
        outerMap.put('user', userMap);
        outerMap.put('pseudonym', pseudonymMap);
        outerMap.put('communication_channel', communicationChannelMap);
        String jsonUser = JSON.serializePretty(outerMap, true);

        return jsonUser;
    }

    private static CanvasUser__c jsonToUser(String jsonUser, CanvasUser__c canvasUser) {
        // update a CanvasUser__c object with some values from a JSON response 
        Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(jsonUser);
        
        canvasUser.CanvasUserId__c = (Integer) objMap.get('id');
        canvasUser.ConfirmationUrl__c = (String) objMap.get('confirmation_url');

        return canvasUser; 
    }

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

    private static CanvasEnrollment__c jsonToEnrollment(String jsonEnrollment, CanvasEnrollment__c canvasEnrollment) {
        Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(jsonEnrollment);
        if (objMap.get('enrollment_status') == 'active') {
            canvasEnrollment.Status__c = 'Active';
        }
        canvasEnrollment.CanvasEnrollmentId__c = (Integer) objMap.get('id');
        return canvasEnrollment;
    }

    private static HttpRequest prepareRequest(String path, String method, Canvas_Settings__c settings) {
        // get the settings that we'll need 
        String token = settings.token__c;
        System.debug('token: ' + token);
        String base_url = settings.base_url__c;
        String api_base = base_url + 'api/v1/';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(api_base + path);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod(method);
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