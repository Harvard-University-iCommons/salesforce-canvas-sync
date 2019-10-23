trigger syncUserToCanvas on CanvasUser__c (after insert, after update) {
    if (Canvas_Settings__c.getInstance().Active__c) {
        for (CanvasUser__c u : Trigger.new) {
                if(System.isFuture() || System.isBatch()){
                    System.debug('we are in future or batch context - stopping');
                } else {
                    CanvasClient.syncCanvasUser(u.ID);  
                    CanvasHelper.ActivityLogGenerate('AUDIT', 'Sync user to Canvas: '+u.Name, 'Trigger:syncUserToCanvas', null, null, u.Id);                    
                }
        }
    }
}