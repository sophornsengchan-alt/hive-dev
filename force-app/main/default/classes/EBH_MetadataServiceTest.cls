@isTest  
private class EBH_MetadataServiceTest 
{    
    /**
     * Dummy Metadata API web service mock class (see MetadataCreateJobTest.cls for a better example)
     **/
    private class WebServiceMockImpl implements WebServiceMock 
    {
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType) 
        {
            if(request instanceof EBH_MetadataService.retrieve_element)
                response.put('response_x', new EBH_MetadataService.retrieveResponse_element());
            else if(request instanceof EBH_MetadataService.checkDeployStatus_element)
                response.put('response_x', new EBH_MetadataService.checkDeployStatusResponse_element());
            else if(request instanceof EBH_MetadataService.update_element)
                response.put('response_x', new EBH_MetadataService.updateResponse_element());
            else if(request instanceof EBH_MetadataService.listMetadata_element)
                response.put('response_x', new EBH_MetadataService.listMetadataResponse_element());
            else if(request instanceof EBH_MetadataService.checkStatus_element)
                response.put('response_x', new EBH_MetadataService.checkStatusResponse_element());
            else if(request instanceof EBH_MetadataService.create_element)
                response.put('response_x', new EBH_MetadataService.createResponse_element());
            else if(request instanceof EBH_MetadataService.checkRetrieveStatus_element)
                response.put('response_x', new EBH_MetadataService.checkRetrieveStatusResponse_element());
            else if(request instanceof EBH_MetadataService.delete_element)
                response.put('response_x', new EBH_MetadataService.deleteResponse_element());
            else if(request instanceof EBH_MetadataService.describeMetadata_element)
                response.put('response_x', new EBH_MetadataService.describeMetadataResponse_element());
            else if(request instanceof EBH_MetadataService.deploy_element)
                response.put('response_x', new EBH_MetadataService.deployResponse_element());
            return;
        }
    }    

    @IsTest
    private static void coverGeneratedCodeCRUDOperations()
    {   
        // Null Web Service mock implementation
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        EBH_MetadataService metaDataService = new EBH_MetadataService();
        // Invoke operations         
        EBH_MetadataService.MetadataPort metaDataPort = new EBH_MetadataService.MetadataPort();
        metaDataPort.create(null);
        metaDataPort.deleteMetadata(null);
        metaDataPort.updateMetadata(null);      
    }

    @IsTest
    private static void coverGeneratedCodeFileBasedOperations()
    {       
        // Null Web Service mock implementation
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        EBH_MetadataService metaDataService = new EBH_MetadataService();
        // Invoke operations         
        EBH_MetadataService.MetadataPort metaDataPort = new EBH_MetadataService.MetadataPort();
        metaDataPort.retrieve(null);
        metaDataPort.checkDeployStatus(null);
        metaDataPort.updateMetadata(null);
        metaDataPort.listMetadata(null, null);
        metaDataPort.checkStatus(null);
        metaDataPort.describeMetadata(null);
        metaDataPort.checkRetrieveStatus(null);
        metaDataPort.deploy(null, null);
        metaDataPort.checkDeployStatus(null);
    }
        
    @IsTest
    private static void coverGeneratedCodeTypes()
    {              
        // Reference types
        new EBH_MetadataService();
        new EBH_MetadataService.listMetadataResponse_element();
        new EBH_MetadataService.WorkflowRule();
        new EBH_MetadataService.AccountOwnerSharingRule();
        new EBH_MetadataService.RecordTypeTranslation();
        new EBH_MetadataService.checkDeployStatus_element();
        new EBH_MetadataService.CodeCoverageWarning();
        new EBH_MetadataService.FlowApexPluginCall();
        new EBH_MetadataService.FlowInputValidationRule();
        new EBH_MetadataService.FlowFormula();
        new EBH_MetadataService.CustomObjectCriteriaBasedSharingRule();
        new EBH_MetadataService.PasswordPolicies();
        new EBH_MetadataService.QueueSobject();
        new EBH_MetadataService.CaseSharingRules();
        new EBH_MetadataService.PicklistValueTranslation();
        new EBH_MetadataService.OpportunityOwnerSharingRule();
        new EBH_MetadataService.ContactOwnerSharingRule();
        new EBH_MetadataService.CustomDataType();
        new EBH_MetadataService.PrimaryTabComponents();
        new EBH_MetadataService.WorkflowEmailRecipient();
        new EBH_MetadataService.DescribeMetadataResult();
        new EBH_MetadataService.RecordType();
        new EBH_MetadataService.Scontrol();
        new EBH_MetadataService.DashboardComponent();
        new EBH_MetadataService.ContactCriteriaBasedSharingRule();
        new EBH_MetadataService.FilterItem();
        new EBH_MetadataService.Profile();
        new EBH_MetadataService.ReportFilter();
        new EBH_MetadataService.PermissionSetApexClassAccess();
        new EBH_MetadataService.LogInfo();
        new EBH_MetadataService.Layout();
        new EBH_MetadataService.WebLink();
        new EBH_MetadataService.WorkflowTaskTranslation();
        new EBH_MetadataService.FlowElement();
        new EBH_MetadataService.ObjectNameCaseValue();
        new EBH_MetadataService.FlowInputFieldAssignment();
        new EBH_MetadataService.CustomDataTypeTranslation();
        new EBH_MetadataService.DashboardComponentSection();
        new EBH_MetadataService.ReportTypeColumn();
        new EBH_MetadataService.CallOptions_element();
        new EBH_MetadataService.CustomObjectOwnerSharingRule();
        new EBH_MetadataService.CustomFieldTranslation();
        new EBH_MetadataService.AnalyticSnapshot();
        new EBH_MetadataService.FlowRule();
        new EBH_MetadataService.FlowRecordUpdate();
        new EBH_MetadataService.CustomSite();
        new EBH_MetadataService.ReportBlockInfo();
        new EBH_MetadataService.describeMetadataResponse_element();
        new EBH_MetadataService.CaseOwnerSharingRule();
        new EBH_MetadataService.ScontrolTranslation();
        new EBH_MetadataService.DeployMessage();
        new EBH_MetadataService.FlowSubflowInputAssignment();
        new EBH_MetadataService.Group_x();
        new EBH_MetadataService.ReportColumn();
        new EBH_MetadataService.ReportType();
        new EBH_MetadataService.CustomPageWebLink();
        new EBH_MetadataService.CodeCoverageResult();
        new EBH_MetadataService.ApexComponent();
        new EBH_MetadataService.BaseSharingRule();
        new EBH_MetadataService.WorkflowKnowledgePublish();
        new EBH_MetadataService.NetworkAccess();
        new EBH_MetadataService.Workflow();
        new EBH_MetadataService.RecordTypePicklistValue();
        new EBH_MetadataService.describeMetadata_element();
        new EBH_MetadataService.DashboardFilterColumn();
        new EBH_MetadataService.FlowChoice();
        new EBH_MetadataService.ReportParam();
        new EBH_MetadataService.RoleOrTerritory();
        new EBH_MetadataService.FlowStep();
        new EBH_MetadataService.FlowApexPluginCallInputParameter();
        new EBH_MetadataService.WorkflowActionReference();
        new EBH_MetadataService.ProfileObjectPermissions();
        new EBH_MetadataService.Role();
        new EBH_MetadataService.RetrieveResult();
        new EBH_MetadataService.delete_element();
        new EBH_MetadataService.SecuritySettings();
        new EBH_MetadataService.WorkflowTimeTrigger();
        new EBH_MetadataService.CustomObjectSharingRules();
        new EBH_MetadataService.updateResponse_element();
        new EBH_MetadataService.retrieve_element();
        new EBH_MetadataService.create_element();
        new EBH_MetadataService.DescribeMetadataObject();
        new EBH_MetadataService.createResponse_element();
        new EBH_MetadataService.DashboardFilterOption();
        new EBH_MetadataService.checkStatus_element();
        new EBH_MetadataService.LayoutColumn();
        new EBH_MetadataService.WorkflowOutboundMessage();
        new EBH_MetadataService.RunTestSuccess();
        new EBH_MetadataService.Queue();
        new EBH_MetadataService.LeadSharingRules();
        new EBH_MetadataService.NamedFilter();
        new EBH_MetadataService.ListViewFilter();
        new EBH_MetadataService.CampaignOwnerSharingRule();
        new EBH_MetadataService.checkStatusResponse_element();
        new EBH_MetadataService.CustomField();
        new EBH_MetadataService.WorkflowTask();
        new EBH_MetadataService.deployResponse_element();
        new EBH_MetadataService.DataCategory();
        new EBH_MetadataService.FlowOutputFieldAssignment();
        new EBH_MetadataService.EmailTemplate();
        new EBH_MetadataService.ReportAggregateReference();
        new EBH_MetadataService.ObjectUsage();
        new EBH_MetadataService.FileProperties();
        new EBH_MetadataService.CustomTabTranslation();
        new EBH_MetadataService.BusinessProcess();
        new EBH_MetadataService.Flow();
        new EBH_MetadataService.PermissionSet();
        new EBH_MetadataService.PermissionSetObjectPermissions();
        new EBH_MetadataService.ReportCrossFilter();
        new EBH_MetadataService.Report();
        new EBH_MetadataService.FlowSubflowOutputAssignment();
        new EBH_MetadataService.ListView();
        new EBH_MetadataService.FlowRecordCreate();
        new EBH_MetadataService.DashboardTableColumn();
        new EBH_MetadataService.ContactSharingRules();
        new EBH_MetadataService.AccountTerritorySharingRules();
        new EBH_MetadataService.AsyncResult();
        new EBH_MetadataService.ArticleTypeChannelDisplay();
        new EBH_MetadataService.checkRetrieveStatus_element();
        new EBH_MetadataService.ProfileLayoutAssignment();
        new EBH_MetadataService.ReportFolder();
        new EBH_MetadataService.FlowTextTemplate();
        new EBH_MetadataService.RelatedListItem();
        new EBH_MetadataService.FlowNode();
        new EBH_MetadataService.RetrieveRequest();
        new EBH_MetadataService.ListMetadataQuery();
        new EBH_MetadataService.FlowConnector();
        new EBH_MetadataService.CustomApplicationComponent();
        new EBH_MetadataService.FlowRecordLookup();
        new EBH_MetadataService.FieldSet();
        new EBH_MetadataService.ProfileApexClassAccess();
        new EBH_MetadataService.AccountCriteriaBasedSharingRule();
        new EBH_MetadataService.DebuggingHeader_element();
        new EBH_MetadataService.CustomDataTypeComponentTranslation();
        new EBH_MetadataService.FlowRecordDelete();
        new EBH_MetadataService.FlowDecision();
        new EBH_MetadataService.ReportTypeSectionTranslation();
        new EBH_MetadataService.IpRange();
        new EBH_MetadataService.FlowApexPluginCallOutputParameter();
        new EBH_MetadataService.ReportBucketField();
        new EBH_MetadataService.CaseCriteriaBasedSharingRule();
        new EBH_MetadataService.CustomLabel();
        new EBH_MetadataService.Attachment();
        new EBH_MetadataService.SharingRules();
        new EBH_MetadataService.CustomConsoleComponents();
        new EBH_MetadataService.Portal();
        new EBH_MetadataService.DomainWhitelist();
        new EBH_MetadataService.ChartSummary();
        new EBH_MetadataService.RunTestFailure();
        new EBH_MetadataService.Territory();
        new EBH_MetadataService.SharedTo();
        new EBH_MetadataService.FlowRecordFilter();
        new EBH_MetadataService.SubtabComponents();
        new EBH_MetadataService.FlowScreen();
        new EBH_MetadataService.WorkflowAlert();
        new EBH_MetadataService.Picklist();
        new EBH_MetadataService.ReportLayoutSection();
        new EBH_MetadataService.SummaryLayoutItem();
        new EBH_MetadataService.LayoutSection();
        new EBH_MetadataService.ReportTimeFrameFilter();
        new EBH_MetadataService.LayoutSectionTranslation();
        new EBH_MetadataService.DataCategoryGroup();
        new EBH_MetadataService.listMetadata_element();
        new EBH_MetadataService.ValidationRule();
        new EBH_MetadataService.NamedFilterTranslation();
        new EBH_MetadataService.WorkspaceMapping();
        new EBH_MetadataService.MetadataWithContent();
        new EBH_MetadataService.ValidationRuleTranslation();
        new EBH_MetadataService.AccountTerritorySharingRule();
        new EBH_MetadataService.Metadata();
        new EBH_MetadataService.ConsoleComponent();
        new EBH_MetadataService.ReportBucketFieldValue();
        new EBH_MetadataService.OpportunitySharingRules();
        new EBH_MetadataService.HomePageLayout();
        new EBH_MetadataService.FlowSubflow();
        new EBH_MetadataService.FlowScreenField();
        new EBH_MetadataService.SiteWebAddress();
        new EBH_MetadataService.RetrieveMessage();
        new EBH_MetadataService.Dashboard();
        new EBH_MetadataService.EmailFolder();
        new EBH_MetadataService.SessionHeader_element();
        new EBH_MetadataService.SummaryLayout();
        new EBH_MetadataService.FlowCondition();
        new EBH_MetadataService.DeployOptions();
        new EBH_MetadataService.FlowAssignment();
        new EBH_MetadataService.ProfileApplicationVisibility();
        new EBH_MetadataService.UpdateMetadata();
        new EBH_MetadataService.CustomApplicationComponents();
        new EBH_MetadataService.FlowElementReferenceOrValue();
        new EBH_MetadataService.EntitlementTemplate();
        new EBH_MetadataService.ProfileTabVisibility();
        new EBH_MetadataService.ActionOverride();
        new EBH_MetadataService.WorkspaceMappings();
        new EBH_MetadataService.WorkflowAction();
        new EBH_MetadataService.deleteResponse_element();
        new EBH_MetadataService.update_element();
        new EBH_MetadataService.DashboardFolder();
        new EBH_MetadataService.PermissionSetApexPageAccess();
        new EBH_MetadataService.LayoutTranslation();
        new EBH_MetadataService.CustomObject();
        new EBH_MetadataService.Translations();
        new EBH_MetadataService.ApexTrigger();
        new EBH_MetadataService.ReportTypeTranslation();
        new EBH_MetadataService.FlowAssignmentItem();
        new EBH_MetadataService.CustomApplicationTranslation();
        new EBH_MetadataService.CustomLabels();
        new EBH_MetadataService.PackageTypeMembers();
        new EBH_MetadataService.PicklistValue();
        new EBH_MetadataService.RemoteSiteSetting();
        new EBH_MetadataService.deploy_element();
        new EBH_MetadataService.retrieveResponse_element();
        new EBH_MetadataService.ArticleTypeTemplate();
        new EBH_MetadataService.ReportGrouping();
        new EBH_MetadataService.PermissionSetFieldPermissions();
        new EBH_MetadataService.AnalyticSnapshotMapping();
        new EBH_MetadataService.LeadCriteriaBasedSharingRule();
        new EBH_MetadataService.SharingRecalculation();
        new EBH_MetadataService.ProfileLoginIpRange();
        new EBH_MetadataService.WebLinkTranslation();
        new EBH_MetadataService.ObjectRelationship();
        new EBH_MetadataService.ListPlacement();
        new EBH_MetadataService.SiteRedirectMapping();
        new EBH_MetadataService.OwnerSharingRule();
        new EBH_MetadataService.WorkflowFieldUpdate();
        new EBH_MetadataService.LetterheadLine();
        new EBH_MetadataService.OpportunityCriteriaBasedSharingRule();
        new EBH_MetadataService.CustomTab();
        new EBH_MetadataService.FlowChoiceUserInput();
        new EBH_MetadataService.Letterhead();
        new EBH_MetadataService.ReportTypeColumnTranslation();
        new EBH_MetadataService.CustomPageWebLinkTranslation();
        new EBH_MetadataService.DocumentFolder();
        new EBH_MetadataService.FlowConstant();
        new EBH_MetadataService.ProfileRecordTypeVisibility();
        new EBH_MetadataService.PackageVersion();
        new EBH_MetadataService.CustomLabelTranslation();
        new EBH_MetadataService.ReportChart();
        new EBH_MetadataService.checkRetrieveStatusResponse_element();
        new EBH_MetadataService.LeadOwnerSharingRule();
        new EBH_MetadataService.ProfileFieldLevelSecurity();
        new EBH_MetadataService.SharingReason();
        new EBH_MetadataService.RunTestsResult();
        new EBH_MetadataService.PermissionSetUserPermission();
        new EBH_MetadataService.MiniLayout();
        new EBH_MetadataService.FlowVariable();
        new EBH_MetadataService.ProfileLoginHours();
        new EBH_MetadataService.DashboardFilter();
        new EBH_MetadataService.CodeLocation();
        new EBH_MetadataService.ReportBucketFieldSourceValue();
        new EBH_MetadataService.FieldSetItem();
        new EBH_MetadataService.ReportFilterItem();
        new EBH_MetadataService.FlowDynamicChoiceSet();
        new EBH_MetadataService.CustomDataTypeComponent();
        new EBH_MetadataService.CustomObjectTranslation();
        new EBH_MetadataService.CustomApplication();
        new EBH_MetadataService.ReportAggregate();
        new EBH_MetadataService.ApexClass();
        new EBH_MetadataService.CampaignSharingRules();
        new EBH_MetadataService.DebuggingInfo_element();
        new EBH_MetadataService.Package_x();
        new EBH_MetadataService.SessionSettings();
        new EBH_MetadataService.Document();
        new EBH_MetadataService.Folder();
        new EBH_MetadataService.DeployResult();
        new EBH_MetadataService.CampaignCriteriaBasedSharingRule();
        new EBH_MetadataService.LayoutItem();
        new EBH_MetadataService.ProfileApexPageAccess();
        new EBH_MetadataService.SharingReasonTranslation();
        new EBH_MetadataService.checkDeployStatusResponse_element();
        new EBH_MetadataService.ReportColorRange();
        new EBH_MetadataService.SearchLayouts();
        new EBH_MetadataService.LetterheadHeaderFooter();
        new EBH_MetadataService.HomePageComponent();
        new EBH_MetadataService.AccountSharingRules();
        new EBH_MetadataService.MobileSettings();
        new EBH_MetadataService.EscalationRules();
        new EBH_MetadataService.KnowledgeAnswerSettings();
        new EBH_MetadataService.ExternalDataSource();
        new EBH_MetadataService.EntitlementProcess();
        new EBH_MetadataService.IdeasSettings();
        new EBH_MetadataService.Country();
        new EBH_MetadataService.ReputationLevels();
        new EBH_MetadataService.KnowledgeSitesSettings();
        new EBH_MetadataService.AddressSettings();
        new EBH_MetadataService.ProfileExternalDataSourceAccess();
        new EBH_MetadataService.CallCenterItem();
        new EBH_MetadataService.CallCenter();
        new EBH_MetadataService.PermissionSetExternalDataSourceAccess();
        new EBH_MetadataService.PermissionSetTabSetting();
        new EBH_MetadataService.AuthProvider();
        new EBH_MetadataService.EmailToCaseSettings();
        new EBH_MetadataService.EscalationAction();
        new EBH_MetadataService.State();
        new EBH_MetadataService.AssignmentRule();
        new EBH_MetadataService.AutoResponseRule();
        new EBH_MetadataService.CaseSettings();
        new EBH_MetadataService.ChatterAnswersSettings();
        new EBH_MetadataService.CountriesAndStates();
        new EBH_MetadataService.SFDCMobileSettings();
        new EBH_MetadataService.EntitlementProcessMilestoneItem();
        new EBH_MetadataService.TouchMobileSettings();
        new EBH_MetadataService.AssignmentRules();
        new EBH_MetadataService.ContractSettings();
        new EBH_MetadataService.KnowledgeCaseSettings();
        new EBH_MetadataService.ChatterAnswersReputationLevel();
        new EBH_MetadataService.KnowledgeSettings();
        new EBH_MetadataService.Community();
        new EBH_MetadataService.AutoResponseRules();
        new EBH_MetadataService.EmailToCaseRoutingAddress();
        new EBH_MetadataService.RuleEntry();
        new EBH_MetadataService.EntitlementSettings();
        new EBH_MetadataService.CriteriaBasedSharingRule();
        new EBH_MetadataService.ApexPage();
        new EBH_MetadataService.WorkflowSend();
        new EBH_MetadataService.ChatterMobileSettings();
        new EBH_MetadataService.CallCenterSection();
        new EBH_MetadataService.EntitlementProcessMilestoneTimeTrigger();
        new EBH_MetadataService.StaticResource();
        new EBH_MetadataService.MilestoneType();
        new EBH_MetadataService.FiscalYearSettings();
        new EBH_MetadataService.CompanySettings();
        new EBH_MetadataService.WebToCaseSettings();
        new EBH_MetadataService.EscalationRule();
        new EBH_MetadataService.DashboardMobileSettings();
        new EBH_MetadataService.FieldOverride();
        new EBH_MetadataService.QuotasSettings();
        new EBH_MetadataService.Skill();
        new EBH_MetadataService.AgentConfigProfileAssignments();
        new EBH_MetadataService.LiveAgentSettings();
        new EBH_MetadataService.SkillAssignments();
        new EBH_MetadataService.ActivitiesSettings();
        new EBH_MetadataService.LiveAgentConfig();
        new EBH_MetadataService.ApprovalPageField();
        new EBH_MetadataService.QuickActionList();
        new EBH_MetadataService.LiveChatButtonDeployments();
        new EBH_MetadataService.InstalledPackage();
        new EBH_MetadataService.PushNotification();
        new EBH_MetadataService.LiveChatAgentConfig();
        new EBH_MetadataService.AdjustmentsSettings();                               
        new EBH_MetadataService.ForecastingSettings();                                
        new EBH_MetadataService.QuickActionListItem();           
        new EBH_MetadataService.Branding();          
        new EBH_MetadataService.QuickActionLayoutItem();                     
        new EBH_MetadataService.OpportunityListFieldsSelectedSettings();        
        new EBH_MetadataService.ApprovalStepRejectBehavior();
        new EBH_MetadataService.FolderShare();   
        new EBH_MetadataService.ApprovalEntryCriteria();                                
        new EBH_MetadataService.ProductSettings();                                
        new EBH_MetadataService.OpportunitySettings();              
        new EBH_MetadataService.LiveChatDeployment();                                
        new EBH_MetadataService.QuickActionLayoutColumn();           
        new EBH_MetadataService.GlobalQuickActionTranslation();      
        new EBH_MetadataService.ApprovalStepApprover();                                
        new EBH_MetadataService.QuoteSettings();         
        new EBH_MetadataService.LiveChatButton();                                
        new EBH_MetadataService.Network();
        new EBH_MetadataService.LiveChatDeploymentDomainWhitelist();
        new EBH_MetadataService.KnowledgeLanguageSettings();
        new EBH_MetadataService.Approver();
        new EBH_MetadataService.SamlSsoConfig();
        new EBH_MetadataService.ApprovalSubmitter();
        new EBH_MetadataService.DataSourceSettings();
        new EBH_MetadataService.KeyboardShortcuts();
        new EBH_MetadataService.ApprovalStep();
        new EBH_MetadataService.AgentConfigAssignments();
        new EBH_MetadataService.QuickAction();
        new EBH_MetadataService.DefaultShortcut();
        new EBH_MetadataService.ApprovalAction();
        new EBH_MetadataService.KnowledgeLanguage();
        new EBH_MetadataService.LiveChatButtonSkills();
        new EBH_MetadataService.SkillUserAssignments();
        new EBH_MetadataService.NextAutomatedApprover();
        new EBH_MetadataService.ApprovalProcess();
        new EBH_MetadataService.QuickActionLayout();
        new EBH_MetadataService.PushNotifications();
        new EBH_MetadataService.ForecastRangeSettings();
        new EBH_MetadataService.IdeaReputationLevel();
        new EBH_MetadataService.NetworkTabSet();
        new EBH_MetadataService.SkillProfileAssignments();
        new EBH_MetadataService.CustomShortcut();
        new EBH_MetadataService.PagesToOpen();
        new EBH_MetadataService.AgentConfigUserAssignments();
        new EBH_MetadataService.NetworkMemberGroup();
        new EBH_MetadataService.FindSimilarOppFilter();
        new EBH_MetadataService.QuickActionTranslation();               
    }
}