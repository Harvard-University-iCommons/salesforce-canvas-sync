trigger syncCourseToCanvas on CanvasCourse__c (after insert, after update) {
    for (CanvasCourse__c c : Trigger.new) {
            if(System.isFuture() || System.isBatch()){
                System.debug('we are in future or batch context - stopping');
            } else {
                CanvasClient.syncCanvasCourse(c.ID); 
                ActivityLog__c log = new  ActivityLog__c();
                log.LEVEL__c = 'AUDIT';
                log.Message__c = 'Added course to Canvas '+c.Name;
                log.Source__c='Trigger:syncCourseToCanvas';
                insert log;
            }
    }
}