# Canvas Sync SFDX App

This Salesforce app contains functionality to help manage courses, users and enrollments in Canvas.

## Installation (DRAFT)

Prerequisites:
* Install the `sfdx` command-line tool
* Have a Salesforce Dev Hub org set up
* Create a new scratch org

Steps: 
* Check out this project from GitHub 
* From the project directory, create a new scratch org: 
```
sfdx force:org:create -s -f config/project-scratch-def.json <new scratch org name>
```
* From the project directory, push the code into your scratch org:
```
sfdx force:source:push
```
* Apply the scratch-org permission set:
```
sfdx force:user:permset:assign -n Scratch_org_permission_set
```
* Open the scratch org:
```
sfdx force:org:open
```

After installing this package in your Salesforce org, set up the custom settings: Canvas URL, sub-account ID, and API token. 

## Resources

* sObjects:
    * `CanvasUser__c`: represents a user account in Canvas
    * `CanvasCourse__c`: represents a Canvas course
    * `CanvasEnrollment__c`: represents an enrollment in a Canvas course; links CanvasUser__c and CanvasCourse__c
* Triggers: 
    * `syncUserToCanvas`
    * `syncCourseToCanvas`
    * `syncEnrollmentToCanvas`
* Apex classes:
    * `CanvasClient`: provides some methods that are called by the above triggers which make the actual API calls to Canvas.


