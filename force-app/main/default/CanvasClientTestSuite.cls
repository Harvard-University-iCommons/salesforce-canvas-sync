@isTest
private class CanvasClientTestSuite {

    static testMethod void testSyncCanvasCourse() {
        Canvas_Settings__c settings = new Canvas_Settings__c(ApiGatewayBaseUrl__c = 'api_gateway_base_url',
                                                             ApiGatewayKey__c = 'gateway_key', 
                                                             base_url__c = 'base_url', 
                                                             sub_account_id__c = 5, 
                                                             token__c = 'test_token');
        
        CanvasCourse__c  canvasCourse = new CanvasCourse__c(CanvasCourseId__c = 123,
                                                         CanvasSubAccountId__c = 10,
                                                         Title__c = 'Test Title');
        insert canvasCourse;

        CanvasUser__c canvasUser = new CanvasUser__c(CanvasUserId__c = 1234,
                                                     ConfirmationUrl__c = 'https://canvas.dev.harvard.edu',
                                                     Email__c = 'test@email.com',
                                                     Fullname__c = 'Joe Johnson');
        insert canvasUser;

        CanvasEnrollment__c canvasEnrollment = new CanvasEnrollment__c(CanvasCourse__c = canvasCourse.Id,
                                                                       CanvasEnrollmentId__c = 12345,
                                                                       CanvasUser__c = canvasUser.Id,
                                                                       Status__C = 'Enrolled');
        insert canvasEnrollment;

        Test.startTest();    // Starts the scope of test

        // TODO Change mock data, add tests for helper methods and break out the sync tests into separate tests
        SingleRequestMock fakeResponse = new SingleRequestMock(200, 'Complete', '[{"Name": "sForceTest1"}]', null);

        Test.setMock(HttpCalloutMock.class, fakeResponse);

        CanvasClient.syncCanvasCourse(canvasCourse.Id);

        SingleRequestMock fakeResponse2 = new SingleRequestMock(400, 'Complete', '[{"Name": "sForceTest1"}]', null);

        Test.setMock(HttpCalloutMock.class, fakeResponse2);

        CanvasClient.syncCanvasCourse(canvasCourse.Id);
        CanvasClient.syncCanvasUser(canvasUser.Id);
        CanvasClient.syncEnrollmentToCanvas(canvasEnrollment.Id, 'Update');

        Test.stopTest();     // Ends the scope of test

    } // testSyncCanvasCourse()


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
        System.assertEquals('gateway_key', reqNoGateway.getHeader('Authorization'));
        System.assertEquals('base_url'+'api/v1/'+'test/path/', reqNoGateway.getEndpoint());
        System.assertEquals('Bearer'+'test_token', reqNoGateway.getHeader('x-api-key'));
    } // testPrepareRequest()

} // class CanvasClientTestSuite
