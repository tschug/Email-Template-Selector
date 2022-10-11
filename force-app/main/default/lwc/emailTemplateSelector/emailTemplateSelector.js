import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';

import search from '@salesforce/apex/EmailTemplateSelectorController.search';
import retrieve from '@salesforce/apex/EmailTemplateSelectorController.retrieve';
import preview from '@salesforce/apex/EmailTemplateSelectorController.preview';

/* Object EmailTemplate is not supported in UI API
// Email Template Fields to display on the component
import TEMPLATE_NAME from '@salesforce/schema/EmailTemplate.Name';
import TEMPLATE_ACTIVE from '@salesforce/schema/EmailTemplate.IsActive';
import TEMPLATE_SUBJECT from '@salesforce/schema/EmailTemplate.Subject';
import TEMPLATE_DESCRIPTION from '@salesforce/schema/EmailTemplate.Description';
import TEMPLATE_STYLE from '@salesforce/schema/EmailTemplate.TemplateStyle';
import TEMPLATE_TYPE from '@salesforce/schema/EmailTemplate.TemplateType';
import TEMPLATE_UI_TYPE from '@salesforce/schema/EmailTemplate.UiType';
import TEMPLATE_FOLDER from '@salesforce/schema/EmailTemplate.FolderName';
import TEMPLATE_ENHANCED_LETTERHEAD from '@salesforce/schema/EmailTemplate.EnhancedLetterheadId';
import TEMPLATE_RELATED_ENTITY_TYPE from '@salesforce/schema/EmailTemplate.RelatedEntityType';
import TEMPLATE_BUILDER from '@salesforce/schema/EmailTemplate.IsBuilderContent';
import TEMPLATE_CREATED_ON from '@salesforce/schema/EmailTemplate.CreatedDate';
import TEMPLATE_LAST_MODIFIED_ON from '@salesforce/schema/EmailTemplate.LastModifiedDate';
import TEMPLATE_TIMES_USED from '@salesforce/schema/EmailTemplate.TimesUsed';
import TEMPLATE_LAST_USED_ON from '@salesforce/schema/EmailTemplate.LastUsedDate';

const emailTemplateFields = [
    TEMPLATE_NAME, TEMPLATE_ACTIVE, TEMPLATE_SUBJECT, TEMPLATE_DESCRIPTION,
    TEMPLATE_STYLE, TEMPLATE_TYPE, TEMPLATE_UI_TYPE, TEMPLATE_FOLDER,
    TEMPLATE_ENHANCED_LETTERHEAD, TEMPLATE_RELATED_ENTITY_TYPE, TEMPLATE_BUILDER,
    TEMPLATE_TIMES_USED, TEMPLATE_CREATED_ON, TEMPLATE_LAST_MODIFIED_ON, TEMPLATE_LAST_USED_ON
];
*/

export default class EmailTemplateSelector extends LightningElement {

    @api recordId;          // aware of Record Context
    @api objectApiName;     // aware of Object Context
    @api whereClause = '';  // (Optional) Where clause for SOSL
    @api mappedField = '';  // Email Template's API Field Name for the record
    @api templateField;     // Syntax of template field:  sObject.Field_Name__c 
    @api templateValue;     // Existing template Id from record
    isSelected = false;     // Preview Accordian setting
    errors = [];            // Holds errors
    @api showPreview = false
    showLetterhead = false;
    templatePreview = [];
    @api accordionActiveSections = [];

    // templateName;
    // templateActive;
    // templateSubject;
    // templateDescription;
    // templateStyle;
    // templateType;
    // templateUiType;
    // templateFolder;
    // templateTimesUsed;
    // templateCreatedOn;
    // templateLastModifiedOn;
    // templateLastUsedOn;

    // Use alerts instead of toasts (LEX only) to notify user
    @api notifyViaAlerts = false;

    // Lookup Component Fields
    isMultiEntry = false;
    maxSelectionSize = 1;
    initialSelection = [];
    recentlyViewed = [];
    newRecordOptions = [
        // { value: 'EmailTemplate', label: 'New Email Template' }
    ];

    // Set field to be used when querying for record's mapped value.
    connectedCallback() {
        if(this.mappedField == null || this.mappedField.trim() == ""){
            // THROW ERROR THAT IT'S NOT CONFIGURED
            this.errors = ['Missing field configuration'];
            this.notifyUser('Lookup Configuration Error', 'Email Template Selector is not mapped to a ' + objectApiName + ' field.', 'error');     
        } else {
            this.templateField = this.objectApiName + '.' + this.mappedField;
        }
    }

    // Check the record for an existing value in order to initialize it.
    @wire(getRecord, { recordId: '$recordId', fields: '$templateField' }) record ({error, data}) {
        if(error) {
            this.errors = [error];
            this.templateValue = undefined;
        } else if (data) {
            console.log('Get Record Wire');
            this.templateValue = getFieldValue(data, this.templateField);
            this.errors = [];
            console.log(this.templateValue);
            if(this.templateValue != null){
                this.initLookupResult();
                this.assignPreviewData();
            }
        }
    }
    
    initLookupResult() {
        // Make sure that the lookup is present and if so, set its results
        const lookup = this.template.querySelector('c-lookup');
        if (lookup) {
            console.log('Component on Page');
            retrieve({emailTemplateId: this.templateValue}).then((results) => {
                this.initialSelection = results;
                console.log('initLookup Retrieved');
            })
            .catch((error) => {
                // eslint-disable-next-line no-console
                console.error('Lookup error', JSON.stringify(error));
                this.errors = [error];
                this.notifyUser('Lookup Error', 'An error occured while trying to populate initial value.', 'error');
            });
        }
    }

    assignPreviewData(){
        console.log('Assign preview');
        preview({emailTemplateId: this.templateValue}).then((results) => {
            this.templatePreview = results;
            this.showPreview = true;
        })
        .catch((error) => {
            console.error('Preview error', JSON.stringify(error));
            this.errors = [error];
            this.notifyUser('Unable to Preview', 'An error occured while trying to retrieve tempate data for preview.', 'info');
        });            
    }

    get showLetterhead(){
        if(templatePreview.LetterheadId != null){
            return true;
        }
        return false;
    }

    /* Object EmailTemplate is not supported in UI API
    // Get field values for the Email Template
    @wire(getRecord, { recordId: '$templateValue', fields: emailTemplateFields }) emailTemplate ({error, data}) {
        if(error){
            this.errors = [error];
            this.notifyUser('Email Template Error', error.body.message, 'error');
        } else if (data) {
            this.errors = [];
            this.templateName = getFieldValue(data, TEMPLATE_NAME);
            this.templateActive = getFieldValue(data, TEMPLATE_ACTIVE);
            this.templateSubject = getFieldValue(data, TEMPLATE_SUBJECT);
            this.templateDescription = getFieldValue(data, TEMPLATE_DESCRIPTION);
            this.templateStyle = getFieldValue(data, TEMPLATE_STYLE);
            this.templateType = getFieldValue(data, TEMPLATE_TYPE);
            this.templateUiType = getFieldValue(data, TEMPLATE_UI_TYPE);
            this.templateFolder = getFieldValue(data, TEMPLATE_FOLDER);
            this.templateTimesUsed = getFieldValue(data, TEMPLATE_TIMES_USED);
            this.templateCreatedOn = getFieldValue(data, TEMPLATE_CREATED_ON);
            this.templateLastModifiedOn = getFieldValue(data, TEMPLATE_LAST_MODIFIED_ON);
            this.templateLastUsedOn = getFieldValue(data, TEMPLATE_LAST_USED_ON);

            this.initialSelection = {
                id: this.templateValue,
                sObjectType: 'EmailTemplate',
                icon: 'standard:template',
                title: this.templateSubject,
                subtitle: ''
            }

        }
    }
    */

    /*
     * Handles the lookup search event.
     * Calls the server to perform the search and returns the results to the lookup.
     * @param {event} event `search` event emmitted by the lookup
     */
    handleLookupSearch(event) {
        const lookupElement = event.target;
        // Call Apex endpoint to search for records and pass results to the lookup
        let term = event.detail.searchTerm;
        let ids = event.detail.selectedIds;
        // search(event.detail) // Removed after updating the method's signature.
        search({searchTerm: term, selectedIds: ids, whereClause: this.whereClause})
            .then((results) => {
                lookupElement.setSearchResults(results);
            })
            .catch((error) => {
                this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
                // eslint-disable-next-line no-console
                console.error('Lookup error', JSON.stringify(error));
                this.errors = [error];
            });
    }

    /*
     * Handles the lookup selection change
     * @param {event} event `selectionchange` event emmitted by the lookup.
     * The event contains the list of selected ids.
     */
    handleLookupSelectionChange(event) {
        // eslint-disable-next-line no-unused-vars
        console.dir(event);
        this.checkForErrors();
        if(Array.isArray(this.errors) && !this.errors.length){
            let selection = event.detail;

            if(selection.length) {
                // Assigning Selection
                this.templateValue = selection[0];
                this.showPreview = true;
            } else {
                // Clearing Selection
                this.templateValue = null;
                this.accordionActiveSections = [];
                this.showPreview = false;
            }

            // Display Values
            // Update Record
            this.updateThisRecord();
        }
    }

    updateThisRecord() {
        let fields = {};
        fields['Id'] = this.recordId;
        fields[this.mappedField] = this.templateValue;

        const recordToUpdate = { fields };
        updateRecord(recordToUpdate)
        .then(() => {
            this.notifyUser('Success', 'Record updated with Email Template', 'success');
        })
        .catch(error => {
            this.notifyUser('Error updating record', error.body.message, 'error');
        });
    }

    checkForErrors() {
        this.errors = [];
        const selection = this.template.querySelector('c-lookup').getSelection();
        // Custom validation rule
        if (this.isMultiEntry && selection.length > this.maxSelectionSize) {
            this.errors.push({ message: `You may only select up to ${this.maxSelectionSize} items.` });
        }
        // Enforcing required field
        // if (selection.length === 0) {
        //     this.errors.push({ message: 'Please make a selection.' });
        // }
    }

    notifyUser(title, message, variant) {
        if (this.notifyViaAlerts) {
            // Notify via alert
            // eslint-disable-next-line no-alert
            alert(`${title}\n${message}`);
        } else {
            // Notify via toast (only works in LEX)
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
        }
    }

    handleSetActiveSection() {
        this.isSelected = !this.isSelected;
        if(this.isSelected){
            this.accordionActiveSections = ['A'];
        } else {
            this.accordionActiveSections = [];
        }
    }
}