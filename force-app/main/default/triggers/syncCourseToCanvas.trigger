trigger syncCourseToCanvas on CanvasCourse__c (after insert, after update) {
    for (CanvasCourse__c c : Trigger.new) {
            if(System.isFuture() || System.isBatch()){
                System.debug('we are in future or batch context - stopping');
            } else {
                CanvasClient.syncCanvasCourse(c.ID); 
                CanvasHelper.ActivityLogGenerate('AUDIT', 'Added/Updated course in Canvas: '+c.Name, 'Trigger:syncCourseToCanvas', c.Id, null, null);
            }
    }
}