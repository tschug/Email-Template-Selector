public with sharing class EmailTemplateSelectorController {
    private final static Integer MAX_RESULTS = 5;
    
    @AuraEnabled(cacheable=true scope='global')
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds, String whereClause) {

        // Prepare query
        String searchQuery='FIND \''
        + SearchUtils.escapeSosl(searchTerm) + '*\' IN NAME FIELDS RETURNING EmailTemplate(Id, Name, Subject, TemplateStyle, TemplateType, UiType, FolderName, RelatedEntityType, IsBuilderContent, TimesUsed, CreatedDate, LastModifiedDate, LastUsedDate ';

        if(!String.isBlank(whereClause)){
            searchQuery += ' WHERE ' + whereClause.trim();
        }

        searchQuery += ' ORDER BY Name ASC) LIMIT ' + MAX_RESULTS;
        system.debug(searchQuery);
        // Execute search query
        List<List<SObject>> searchResults = search.query(searchquery);

        // Prepare results
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Extract Email Templates & convert them into LookupSearchResult
        EmailTemplate[] emailTemplates = (List<EmailTemplate>) searchResults[0];
        for (EmailTemplate emailTemplate : emailTemplates) {
            String subtitle = emailTemplate.UiType == null ? 'Email Template' : 'Email Template • ' + emailTemplate.UiType;
            results.add(
                new LookupSearchResult(
                    emailTemplate.Id, 
                    'EmailTemplate', 
                    'standard:template',
                    emailTemplate.Name, 
                    subtitle
                )
            );
        }

        // Optionally sort all results on title
        results.sort();

        return results;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<LookupSearchResult> retrieve(String emailTemplateId){

        List<LookupSearchResult> results = new List<LookupSearchResult>();

        for(EmailTemplate emailTemplate :  [
            SELECT Id, Name, Subject, TemplateStyle, TemplateType, UiType, 
                FolderName, RelatedEntityType, IsBuilderContent, TimesUsed, 
                CreatedDate, LastModifiedDate, LastUsedDate
            FROM EmailTemplate
            WHERE Id = :emailTemplateId
            LIMIT 1
        ]) {
            String subtitle = emailTemplate.UiType == null ? 'Email Template' : 'Email Template • ' + emailTemplate.UiType;
            results.add(
                new LookupSearchResult(
                    emailTemplate.Id, 
                    'EmailTemplate', 
                    'standard:template',
                    emailTemplate.Name, 
                    subtitle
                )
            );
        }

        return results;

    }

    @AuraEnabled(cacheable=true scope='global')
    public static eTemplate preview(String emailTemplateId){
        
        eTemplate eTemplate = new eTemplate();
        
        for(EmailTemplate emailTemplate : [
            SELECT Id, Name, Subject, Description, 
                BrandTemplateId, EnhancedLetterhead.Id, EnhancedLetterhead.Name, 
                TemplateStyle, TemplateType, UiType, IsActive,
                FolderName, RelatedEntityType, IsBuilderContent, TimesUsed, 
                CreatedDate, LastModifiedDate, LastUsedDate
            FROM EmailTemplate
            WHERE Id = :emailTemplateId
            LIMIT 1
        ]) {
            eTemplate.Id = '/' + emailTemplate.Id;
            eTemplate.Name = emailTemplate.Name;
            eTemplate.Subject = emailTemplate.Subject == null ? '(Blank)' : emailTemplate.Subject;
            eTemplate.Description = emailTemplate.Description == null ? '(Blank)' : emailTemplate.Description;
            eTemplate.UiType = emailTemplate.UiType == 'Aloha' ? 'utility:classic_interface' : 'utility:connected_apps';
            eTemplate.IsActive = emailTemplate.IsActive;
            eTemplate.FolderName = emailTemplate.FolderName;
            eTemplate.RelatedEntityType = emailTemplate.RelatedEntityType == null ? 'None' : emailTemplate.RelatedEntityType;
            eTemplate.TimesUsed = emailTemplate.TimesUsed == null ? '0' : String.valueOf(emailTemplate.TimesUsed);
            eTemplate.CreatedDate = emailTemplate.CreatedDate.format('yyyy-MM-dd h:mm a');
            eTemplate.LastModifiedDate = emailTemplate.LastModifiedDate.format('yyyy-MM-dd h:mm a');
            eTemplate.LastUsedDate = emailTemplate.LastUsedDate == null ? 'Never' : emailTemplate.LastUsedDate.format('yyyy-MM-dd h:mm a');
            switch on emailTemplate.TemplateType {
                when 'html' {
                    eTemplate.TemplateType = 'standard:code_playground';
                    eTemplate.TemplateTypeName = 'HTML Template';
                }	
                when 'text' {
                    eTemplate.TemplateType = 'standard:text_template';
                    eTemplate.TemplateTypeName = 'Text Template';
                }
                when 'visualforce' {
                    eTemplate.TemplateType = 'standard:visualforce_page';
                    eTemplate.TemplateTypeName = 'Visualforce Template';
                }
                when 'custom' {
                    if(emailTemplate.IsBuilderContent) {
                        eTemplate.TemplateType = 'custom:custom104';
                        eTemplate.TemplateTypeName = 'Lightning Template - Builder';
                    } else if (emailTemplate.UiType == 'SFX') {
                        eTemplate.TemplateType = 'custom:custom9';
                        eTemplate.TemplateTypeName = 'Lightning Template';
                    } else {
                        eTemplate.TemplateType = 'standard:custom';
                        eTemplate.TemplateTypeName = 'Custom Template';
                    }
                    
                }
                when else {
                    eTemplate.TemplateType = 'custom:custom108';
                }
            }
           
            if(emailTemplate.EnhancedLetterheadId != null){
                eTemplate.LetterheadName = emailTemplate.EnhancedLetterhead.Name;
                eTemplate.LetterheadId = '/' + emailTemplate.EnhancedLetterhead.Id;
            } else if (emailTemplate.BrandTemplateId != null) {
                eTemplate.LetterheadName =  [SELECT Name FROM BrandTemplate WHERE id = :emailTemplate.BrandTemplateId].Name;
                eTemplate.LetterheadId = '/' + emailTemplate.BrandTemplateId;
            } else {
                eTemplate.LetterheadName = 'N/A';
                eTemplate.LetterheadId = null;
            }

        }

        

        return eTemplate;
    }

    public class eTemplate{
        @AuraEnabled
        public String Id { get; set; }

        @AuraEnabled
        public String Name { get; set; }

        @AuraEnabled
        public String Subject { get; set; }

        @AuraEnabled
        public String Description { get; set; }

        @AuraEnabled
        public String LetterheadName { get; set; }

        @AuraEnabled
        public String LetterheadId { get; set; }

        @AuraEnabled
        public String TemplateType { get; set; }

        @AuraEnabled
        public String UiType { get; set; }

        @AuraEnabled
        public Boolean IsActive { get; set; }

        @AuraEnabled
        public String FolderName { get; set; }

        @AuraEnabled
        public String RelatedEntityType { get; set; }

        @AuraEnabled
        public String TemplateTypeName { get; set; }

        @AuraEnabled
        public String TimesUsed { get; set; }

        @AuraEnabled
        public String CreatedDate { get; set; }

        @AuraEnabled
        public String LastModifiedDate { get; set; }

        @AuraEnabled
        public String LastUsedDate { get; set; }
    }
}
