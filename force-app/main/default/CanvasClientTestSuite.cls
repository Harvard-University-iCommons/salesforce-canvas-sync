@isTest
private class CanvasClientTestSuite {

    static testMethod void testSyncCanvasCourse() {
        Test.startTest();    // Starts the scope of test

        Canvas_Settings__c settings = new Canvas_Settings__c(ApiGatewayBaseUrl__c = 'api_gateway_base_url',
                                                             ApiGatewayKey__c = 'gateway_key', 
                                                             base_url__c = 'base_url', 
                                                             sub_account_id__c = 5, 
                                                             token__c = 'test_token');
        insert settings;
        
        CanvasCourse__c  canvasCourse = new CanvasCourse__c(CanvasCourseId__c = 123,
                                                            CanvasSubAccountId__c = 10,
                                                            Term__c = '1',
                                                            Title__c = 'Test Title');        // insert canvasCourse;        

        CanvasUser__c canvasUser = new CanvasUser__c(CanvasUserId__c = 1234,
                                                     ConfirmationUrl__c = 'https://canvas.dev.harvard.edu',
                                                     Email__c = 'test@email.com',
                                                     Fullname__c = 'Joe Johnson');

        CanvasUser__c canvasUserNoId = new CanvasUser__c(CanvasUserId__c = 1234,
                                                         ConfirmationUrl__c = 'https://canvas.dev.harvard.edu',
                                                         Email__c = 'test@email.com',
                                                         Fullname__c = 'Joe Johnson');

        String testCourseJson = '{"id":6623,"name":"Test Course","account_id":749,"uuid":"Fy0Sx97QMJGQ0yKZdYqx7xJ9yH1bY2Qv9GG33pxU","start_at":null,"conclude_at":null,"grading_standard_id":null,"is_public":null,"allow_student_forum_attachments":false,"course_code":"TestCourseCode","default_view":"modules","root_account_id":1,"enrollment_term_id":1,"open_enrollment":null,"allow_wiki_comments":null,"self_enrollment":null,"license":null,"restrict_enrollments_to_course_dates":false,"end_at":null,"public_syllabus":false,"public_syllabus_to_auth":false,"storage_quota_mb":1000,"is_public_to_auth_users":false,"hide_final_grades":false,"apply_assignment_group_weights":false,"calendar":{"ics":"https://canvas.dev.tlt.harvard.edu/feeds/calendars/course_Fy0Sx97QMJGQ0yKZdYqx7xJ9yH1bY2Qv9GG33pxU.ics"},"time_zone":"America/New_York","blueprint":false,"sis_course_id":"a013D000004J5xkQAC","sis_import_id":null,"integration_id":null,"workflow_state":"unpublished"}';
        String testUserJson = '{"id":12345,"name":"Christopher Thornton","sortable_name":"Thornton, Christopher","short_name":"Aikaterini-Pavlina Tsoka","sis_user_id":"10930448","integration_id":null,"sis_import_id":36425,"login_id":"10930448"},{"id":154483,"name":"Christopher Thornton","sortable_name":"Thornton, Christopher","short_name":"Christopher Thornton","sis_user_id":"913","integration_id":null,"sis_import_id":49189,"login_id":"913"}';

        SingleRequestMock courseDoesntExistResp = new SingleRequestMock(200, 'Complete', testCourseJson, null);
        Test.setMock(HttpCalloutMock.class, courseDoesntExistResp);
        insert canvasCourse;

        SingleRequestMock courseDoesExistResp = new SingleRequestMock(404, 'Complete', testCourseJson, null);
        Test.setMock(HttpCalloutMock.class, courseDoesExistResp);
        CanvasClient.syncCanvasCourse(canvasCourse.Id);

        Test.stopTest();

    } // testSyncCanvasCourse()

    static testMethod void testSyncCanvasUser() {
        Test.startTest();    // Starts the scope of test

        Canvas_Settings__c settings = new Canvas_Settings__c(ApiGatewayBaseUrl__c = 'api_gateway_base_url',
                                                             ApiGatewayKey__c = 'gateway_key', 
                                                             base_url__c = 'base_url', 
                                                             sub_account_id__c = 5, 
                                                             token__c = 'test_token');
        insert settings;
        
        CanvasCourse__c  canvasCourse = new CanvasCourse__c(CanvasCourseId__c = 123,
                                                            CanvasSubAccountId__c = 10,
                                                            Title__c = 'Test Title');        // insert canvasCourse;        

        CanvasUser__c canvasUser = new CanvasUser__c(CanvasUserId__c = 1234,
                                                     ConfirmationUrl__c = 'https://canvas.dev.harvard.edu',
                                                     Email__c = 'test@email.com',
                                                     Fullname__c = 'Joe Johnson');

        CanvasUser__c canvasUserNoId = new CanvasUser__c(CanvasUserId__c = 1234,
                                                         ConfirmationUrl__c = 'https://canvas.dev.harvard.edu',
                                                         Email__c = 'test@email.com',
                                                         Fullname__c = 'Joe Johnson');

        String testCourseJson = '{"id":6623,"name":"Test Course","account_id":749,"uuid":"Fy0Sx97QMJGQ0yKZdYqx7xJ9yH1bY2Qv9GG33pxU","start_at":null,"conclude_at":null,"grading_standard_id":null,"is_public":null,"allow_student_forum_attachments":false,"course_code":"TestCourseCode","default_view":"modules","root_account_id":1,"enrollment_term_id":1,"open_enrollment":null,"allow_wiki_comments":null,"self_enrollment":null,"license":null,"restrict_enrollments_to_course_dates":false,"end_at":null,"public_syllabus":false,"public_syllabus_to_auth":false,"storage_quota_mb":1000,"is_public_to_auth_users":false,"hide_final_grades":false,"apply_assignment_group_weights":false,"calendar":{"ics":"https://canvas.dev.tlt.harvard.edu/feeds/calendars/course_Fy0Sx97QMJGQ0yKZdYqx7xJ9yH1bY2Qv9GG33pxU.ics"},"time_zone":"America/New_York","blueprint":false,"sis_course_id":"a013D000004J5xkQAC","sis_import_id":null,"integration_id":null,"workflow_state":"unpublished"}';
        String testUserJson = '[{"id":12345,"name":"Christopher Thornton","sortable_name":"Thornton, Christopher","short_name":"Aikaterini-Pavlina Tsoka","sis_user_id":"10930448","integration_id":null,"sis_import_id":36425,"login_id":"10930448"},{"id":154483,"name":"Christopher Thornton","sortable_name":"Thornton, Christopher","short_name":"Christopher Thornton","sis_user_id":"913","integration_id":null,"sis_import_id":49189,"login_id":"913"}]';
        
        SingleRequestMock userExistsResp = new SingleRequestMock(200, 'Complete', testUserJson, null);
        Test.setMock(HttpCalloutMock.class, userExistsResp);
        insert canvasUser;

        canvasUser.CanvasUserId__c = null;
        update canvasUser;
        // CanvasClient.syncCanvasUser(canvasUser.id);
        
        Test.stopTest();
    }

    static testMethod void testSyncEnrollmentToCanvas() {
        Test.startTest();    // Starts the scope of test

        Canvas_Settings__c settings = new Canvas_Settings__c(ApiGatewayBaseUrl__c = 'api_gateway_base_url',
                                                             ApiGatewayKey__c = 'gateway_key', 
                                                             base_url__c = 'base_url', 
                                                             sub_account_id__c = 5, 
                                                             token__c = 'test_token');
        insert settings;
        
        CanvasCourse__c  canvasCourse = new CanvasCourse__c(CanvasCourseId__c = 123,
                                                            CanvasSubAccountId__c = 10,
                                                            Title__c = 'Test Title');        // insert canvasCourse;        

        CanvasUser__c canvasUser = new CanvasUser__c(CanvasUserId__c = 1234,
                                                     ConfirmationUrl__c = 'https://canvas.dev.harvard.edu',
                                                     Email__c = 'test@email.com',
                                                     Fullname__c = 'Joe Johnson');

        CanvasUser__c canvasUserNoId = new CanvasUser__c(CanvasUserId__c = 1234,
                                                         ConfirmationUrl__c = 'https://canvas.dev.harvard.edu',
                                                         Email__c = 'test@email.com',
                                                         Fullname__c = 'Joe Johnson');

        String testCourseJson = '{"id":6623,"name":"Test Course","account_id":749,"uuid":"Fy0Sx97QMJGQ0yKZdYqx7xJ9yH1bY2Qv9GG33pxU","start_at":null,"conclude_at":null,"grading_standard_id":null,"is_public":null,"allow_student_forum_attachments":false,"course_code":"TestCourseCode","default_view":"modules","root_account_id":1,"enrollment_term_id":1,"open_enrollment":null,"allow_wiki_comments":null,"self_enrollment":null,"license":null,"restrict_enrollments_to_course_dates":false,"end_at":null,"public_syllabus":false,"public_syllabus_to_auth":false,"storage_quota_mb":1000,"is_public_to_auth_users":false,"hide_final_grades":false,"apply_assignment_group_weights":false,"calendar":{"ics":"https://canvas.dev.tlt.harvard.edu/feeds/calendars/course_Fy0Sx97QMJGQ0yKZdYqx7xJ9yH1bY2Qv9GG33pxU.ics"},"time_zone":"America/New_York","blueprint":false,"sis_course_id":"a013D000004J5xkQAC","sis_import_id":null,"integration_id":null,"workflow_state":"unpublished"}';
        String testUserJson = '{"id":12345,"name":"Christopher Thornton","sortable_name":"Thornton, Christopher","short_name":"Aikaterini-Pavlina Tsoka","sis_user_id":"10930448","integration_id":null,"sis_import_id":36425,"login_id":"10930448"},{"id":154483,"name":"Christopher Thornton","sortable_name":"Thornton, Christopher","short_name":"Christopher Thornton","sis_user_id":"913","integration_id":null,"sis_import_id":49189,"login_id":"913"}';
        
        SingleRequestMock courseExistsResp = new SingleRequestMock(200, 'Complete', testCourseJson, null);
        Test.setMock(HttpCalloutMock.class, courseExistsResp);

        insert canvasUser;
        insert canvasCourse;

        CanvasEnrollment__c canvasEnrollment = new CanvasEnrollment__c(CanvasCourse__c = canvasCourse.Id,
                                                                       CanvasEnrollmentId__c = 12345,
                                                                       CanvasUser__c = canvasUser.Id,
                                                                       Status__C = 'Active');

        insert canvasEnrollment;
        // CanvasClient.syncEnrollmentToCanvas(canvasEnrollment.Id, 'delete');

        CanvasClient.subscribeToBlueprintCourse(canvasCourse.Id, 123,123);

        // Putting in calls to methods to get some additional coverage
        CanvasClient.userToJson(canvasUser);
        
        Test.stopTest();
    }

    // TODO Implement unit tests for the following methods
    // public static void syncCanvasCourse(Id canvasCourseRecordId)
    // public static void syncCanvasUser(Id canvasUserRecordId)
    // public static void syncEnrollmentToCanvas(Id canvasEnrollmentId, String requestType)
    // private static void  subscribeToBlueprintCourse(Decimal BlueprintCanvasCourseId, Decimal currentCanvasCourseId)
    // private static String courseToJson(CanvasCourse__c canvasCourse)
    // private static CanvasCourse__c jsonToCourse(String jsonCourse, CanvasCourse__c canvasCourse)
    // private static String userToJson(CanvasUser__c canvasUser)
    // private static String userToJsonForUpdate(CanvasUser__c canvasUser)
    // private static CanvasUser__c jsonToUser(String jsonUser, CanvasUser__c canvasUser)
    // private static String enrollmentToJson(CanvasEnrollment__c canvasEnrollment)
    // private static CanvasEnrollment__c jsonToEnrollment(String jsonEnrollment, CanvasEnrollment__c canvasEnrollment)


    static testMethod void testPrepareRequest(){
        // TODO Have settings as a global setup
        Canvas_Settings__c settings = new Canvas_Settings__c(ApiGatewayBaseUrl__c = 'api_gateway_base_url',
                                                             ApiGatewayKey__c = 'gateway_key', 
                                                             base_url__c = 'base_url', 
                                                             sub_account_id__c = 5, 
                                                             token__c = 'test_token');

        HttpRequest reqUseGateway = CanvasClient.prepareRequest('test/path/', 'POST', settings, true);
        System.assertEquals('POST', reqUseGateway.getMethod());
        System.assertEquals('api_gateway_base_url'+'api/v1/'+'test/path/', reqUseGateway.getEndpoint());
        System.assertEquals('gateway_key', reqUseGateway.getHeader('x-api-key'));

        HttpRequest reqNoGateway = CanvasClient.prepareRequest('test/path/', 'POST', settings, false);
        System.assertEquals('base_url'+'api/v1/'+'test/path/', reqNoGateway.getEndpoint());
        System.assertEquals('Bearer '+'test_token', reqNoGateway.getHeader('Authorization'));
    } // testPrepareRequest()

} // class CanvasClientTestSuite