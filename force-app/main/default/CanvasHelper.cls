public with sharing class CanvasHelper {

    public static void ActivityLogGenerate(String level, String message, String source, Id courseId, Id enrollmentId, Id userId) {
        CanvasActivityLog__c log = new  CanvasActivityLog__c();
        log.LEVEL__c = level;                          
        log.Message__c = message;
        log.Source__c = source;
        log.CanvasCourse__c = courseId;
        log.CanvasEnrollment__c = enrollmentId;
        log.CanvasUser__c = userId;
        insert log; 
    }
}