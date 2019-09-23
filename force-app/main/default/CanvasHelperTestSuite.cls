@isTest
private class CanvasHelperTestSuite {

    static testMethod void runPositiveTestCases() {
        CanvasHelper.ActivityLogGenerate('AUDIT', 'test message', 'Trigger:syncUserToCanvas', null, null, null);
        CanvasActivityLog__c log = [SELECT LEVEL__c, Message__c, Source__c FROM CanvasActivityLog__c];

        System.assertEquals('AUDIT', log.LEVEL__c);
        System.assertEquals('test message', log.Message__c);
        System.assertEquals('Trigger:syncUserToCanvas', log.Source__c);
    } // runPositiveTestCases()

} // class CanvasHelperTestSuite