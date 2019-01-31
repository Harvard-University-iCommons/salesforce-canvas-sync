trigger syncEnrollmentToCanvas on CanvasEnrollment__c (after insert, after update, before delete) {
    if(System.isFuture() || System.isBatch()){
        System.debug('we are in future or batch context - stopping');
    } else {
        if(Trigger.isDelete) {
            for (CanvasEnrollment__c e : Trigger.old) {
                CanvasClient.syncEnrollmentToCanvas(e.Id, 'delete');   
                CanvasHelper.ActivityLogGenerate('AUDIT', 'Deleted enrollment from Canvas: '+e.Name, 'Trigger:syncEnrollmentToCanvas');
            }
        } else {
            for (CanvasEnrollment__c e : Trigger.new) {
                CanvasClient.syncEnrollmentToCanvas(e.Id, 'other');   
                CanvasHelper.ActivityLogGenerate('AUDIT', 'Added/updated enrollment in Canvas: '+e.Name, 'Trigger:syncEnrollmentToCanvas');
            }       
        }
    }
}
