@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {

    // Implement this interface method

    global HTTPResponse respond(HTTPRequest req) {

        // Optionally, only send a mock response for a specific endpoint

        // and method.
        Canvas_Settings__c settings = new Canvas_Settings__c();
        settings.base_url__c = 'canvas_url';

        // currently hardcoding the null as it's not clear how to pass the base url
        System.assertEquals('nullapi/v1/courses/123', req.getEndpoint());

        System.assertEquals('GET', req.getMethod());
        
         

        // Create a fake response

        HttpResponse res = new HttpResponse();

        res.setHeader('Content-Type', 'application/json');

        res.setBody('{"example":"test"}');

        res.setStatusCode(201);

        return res;

    }

}