/*********************************************************************************************************************************
@ Class:          ContractCreationFlowService
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        Service class for screen flow: Contract - User Guided Flow For Contract Creation
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.04.2024 / Mony Nou / Created the class
@               : 05.06.2024 / Sambath Seng / US-0015361 - User guided flow for contract creation - updates
@               : 02.07.2024 / Mony Nou / US-0015322 - User guided flow for contract creation - UX
@               : 23.01.2025 / Mony Nou / US-0015675 - Update Executed contract check logic in the contract guided flow
*********************************************************************************************************************************/
public with sharing class ContractCreationFlowService {
    
    private final static String STATUS_EXECUTED = 'Executed';
    private final static String DASHSYMBOL = ' - '; //MN-23012025-US-0015675

    public class SellerRecord {
        @InvocableVariable
        public String sellerId;
    }

    public class Result {
        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Validate Sellers' description='Queries for executed contracts based on selected sellers')
    public static List<Result> queryExecutedContracts(List<List<String>> sellerRecords) {

        List<Result> results = new List<Result>();
        /*
        Set<String> sSellerIds = new Set<String>();

        for (SellerRecord sellerRecord : sellerRecords) {
            sSellerIds.add(sellerRecord.sellerId);
        }
        */
        // SB 05.06.2024 US-0015361 add RecordType.Name, StartDate, EndDate to query
        String soqlContract = 'select Id, EBH_ContractNumber__c, EBH_ContractNumber__r.ContractNumber, EBH_BusinessName__r.Name, EBH_ContractNumber__r.RecordType.Name, EBH_ContractNumber__r.StartDate, EBH_ContractNumber__r.EndDate from EBH_ContractSeller__c where EBH_ContractNumber__r.Status =:STATUS_EXECUTED and EBH_BusinessName__c IN:sellerRecords ORDER BY EBH_ContractNumber__r.RecordType.Name';
        List<EBH_ContractSeller__c> lstContractSellers = (List<EBH_ContractSeller__c>) ApexSafe.query().secCheck(false).doQuery(soqlContract,new Map<String, Object> {'STATUS_EXECUTED' => STATUS_EXECUTED, 'sellerRecords' => sellerRecords[0]});

        String message = '';

        if (!lstContractSellers.isEmpty()) {
            
            // Construct the base message
            String baseMessage = 'Click to view the live contract(s)\n\n'; //MN-02072024-US-0015322
            String contractsInfo = '';

            // Query for contracts with status 'Executed' for the given seller IDs
            for (EBH_ContractSeller__c contseller : lstContractSellers) {
                String contractLink = Site.getBaseUrl() + '/' + contseller.EBH_ContractNumber__c;

                String conLink = '<a target="_blank" href="' + contractLink + '">' + contseller.EBH_ContractNumber__r.ContractNumber + '</a>';

                // SB 05.06.2024 US-0015361
                // contractsInfo += contseller.EBH_BusinessName__r.Name + ' - ' + conLink + '\n';

                //MN-02072024-US-0015322
                //contractsInfo += contseller.EBH_BusinessName__r.Name + ': ' + contseller.EBH_ContractNumber__r.RecordType.Name + ' - ' + conLink + ', ' + contseller.EBH_ContractNumber__r.StartDate.format() + ' - ' + contseller.EBH_ContractNumber__r.EndDate.format() + '\n';
                //MN-23012025-US-0015675
                //contractsInfo += contseller.EBH_BusinessName__r.Name + ' ' + contseller.EBH_ContractNumber__r.RecordType.Name + ' ' + conLink + ' Contract Dates: ' + contseller.EBH_ContractNumber__r.StartDate.format() + ' - ' + contseller.EBH_ContractNumber__r.EndDate.format() + '\n';
                
                //MN-23012025-US-0015675 -- START
                contractsInfo += conLink + DASHSYMBOL + contseller.EBH_ContractNumber__r.RecordType.Name;
                if (contseller.EBH_ContractNumber__r.StartDate != null && contseller.EBH_ContractNumber__r.EndDate != null) { // Display contract dates only if they are not null
                    contractsInfo += DASHSYMBOL + contseller.EBH_ContractNumber__r.StartDate.format() + ' / ' + contseller.EBH_ContractNumber__r.EndDate.format();
                }
                contractsInfo += '\n';
                //MN-23012025-US-0015675 -- END
            }
            message = baseMessage + contractsInfo;
        }
        
        // Add the result to the list
        Result res = new Result();
        res.message = message;
        results.add(res);

        return results;
    }
}