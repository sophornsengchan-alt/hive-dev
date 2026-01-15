/*********************************************************************************************************************************
@ Class:          EBH_RelatedSellersController
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        [EBH] (EPH-2855) - Shows the related Sellers on the Legal Entity page as inline vf
                  EPH-5 : Seller 360, Customer Management
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.07.2017 / JOY MONDOL (jmondol@deloitte.co.uk) / Created the page.
                  07.02.2025 / Sothea Horn / US-0016450 - Retiring old related seller list on Legal Entity record
*********************************************************************************************************************************/
public with sharing class EBH_RelatedSellersController {
    
    private static final String FR_BLANK = '';
    private static final String ATCH_COMMA = ',';
    private static final String PLACEH = '[PLACEHOLDER]';

    Id parentId;
    
    public Integer RowCount { get; set; }   
    public Decimal PageCount { get; set; }
    public Integer PageNumber { get; set; }
    public Integer PageNumberDisplay { get; set; }
    public Integer PageSize { get { return Integer.valueOf(Label.EBH_DistinctSellerPageSize); } }
    
    public List<Account> Sellers { 
        get {
            return Database.query(SellerQuery);
        }
    }
    
    public String SellerQuery {
        get {
            //07.02.2025 / Sothea Horn / US-0016450 - add sorting by GMV (last 12 months), showing the highest value first.
            String query = 'SELECT Id[PLACEHOLDER] FROM Account WHERE ParentId =: parentId AND RecordType.DeveloperName = \'EBH_Seller\' '
            + 'ORDER BY EBH_GMVLast12Months__c DESC NULLS LAST LIMIT :PageSize OFFSET :PageNumber';
            
            String PLACEHOLDER = FR_BLANK;
            
            for(Schema.FieldSetMember fld : SObjectType.Account.FieldSets.EBH_RelatedSellerFields.getFields()) {
                PLACEHOLDER += ATCH_COMMA + fld.getFieldPath();
            }
            
            return !String.isBlank(PLACEHOLDER) ? query.replace(PLACEH, PLACEHOLDER) : 
                   query.replace(PLACEH, FR_BLANK);
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         Constructor - EBH_RelatedSellersController
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        To get the legal entity Id, passed through inline VF page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      ApexPages.StandardController 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public EBH_RelatedSellersController(ApexPages.StandardController controller) {        
        parentId = controller.getId();
        PageNumber = PageNumberDisplay = 0; 
        RowCount = Database.countQuery(EBH_ConstantsUtility.RSC_SELLERCOUNTQUERY);
        PageCount = Math.ceil(Decimal.valueOf(RowCount).divide(PageSize, 1));
    }
    
    /*****************************************************************************************************************************
    @ Method:         first
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        To get the first page of paginated records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      No Parameters
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public void first() {
        PageNumber = PageNumberDisplay = 0;
    }
    
   /*****************************************************************************************************************************
    @ Method:         next
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        To get the next set of paginated records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      No Parameters
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public void next() {
        PageNumber += PageSize;
        PageNumberDisplay++;
    }
    
    /*****************************************************************************************************************************
    @ Method:         previous
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        To get the previous set of paginated records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      No Parameters
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public void previous() {
        PageNumber -= PageSize;
        PageNumberDisplay--;
    }
    
    /*****************************************************************************************************************************
    @ Method:         last
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Used for getting the last set of records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      No Parameter
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public void last() {
        PageNumber = Integer.valueOf(PageCount - 1) * PageSize;
        PageNumberDisplay = Integer.valueOf(PageCount - 1);
    }
}