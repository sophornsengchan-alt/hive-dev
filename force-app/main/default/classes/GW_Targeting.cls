/*********************************************************************************************************************************
@ Class:          GW_Targeting
@ Migrated From : Advertising Instance (Legacy Code)         
@ Purpose:      : Class for Generate Targeting for Quotelineitem   
----------------------------------------------------------------------------------------------------------------------------------
@ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
*********************************************************************************************************************************/
public with sharing class GW_Targeting {

    public static Id defaultTargetingRecordTypeId {
        get {
            return Schema.SObjectType.Targeting__c.getRecordTypeInfosByDeveloperName().get('Targeting').getRecordTypeId();
        }
    }

    /** 
     * @description Clone Targeting and its associations
     * @param   oldTargetingIds: list of old targing ids
     * @return  Map of old targeting id with its newly create record
     */
    public static Map<Id, Targeting__c> copyTargeting(Set<String> oldTargetingIds){
        Map<Id, Targeting__c> mOldTgId2NewRecord = new Map<Id, Targeting__c>();
        if( oldTargetingIds.isEmpty() ) return mOldTgId2NewRecord;

        TargetingCloner tgCloner = new TargetingCloner(oldTargetingIds);
        tgCloner.doClone();
        for(String oldTargetingId  :tgCloner.mOldTgId2NewRecords.keySet()){
            for(Targeting__c newTargeting: tgCloner.mOldTgId2NewRecords.get(oldTargetingId) ) {
                mOldTgId2NewRecord.put(oldTargetingId, newTargeting);
                break;
            }
        }
        return mOldTgId2NewRecord;
    }
    
    public static void copyTargetings(String fromId, String[] toIds){
        TargetingCloner targetingCloner = new QlisTargetingCloner(fromId, new Set<String>(toIds));
        targetingCloner.doClone();
    }

    public static void copyProdPackageTargetingToLine(String tgId, Set<String> qliIds){
        QlisTargetingCloner targetingCloner = new QlisTargetingCloner();
        targetingCloner.srcTargetings = (List<Targeting__c>) QueryUtil.queryRecords(Util.NS+'Targeting__c',' Id =:value1',new Map<String, Object>{'value1'=>tgId});
        targetingCloner.targetQliIds = qliIds;
        Map<Id, Integer> mapSrcTarId2Qty = new Map<Id, Integer>();
        for(Targeting__c srcTargeting : targetingCloner.srcTargetings){ // 05.06.2021 / Sophal Noch / US-0009753
            mapSrcTarId2Qty.put(srcTargeting.Id, targetingCloner.targetQliIds.size());
        }
        targetingCloner.mapSrcTarId2Qty = mapSrcTarId2Qty;
        targetingCloner.removeTgRecType = true;
        targetingCloner.doClone();
    }

    /*********************************************************************************************************************************
    @ Method:          copyProdPackageTargetingToLine
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        US-0008850 - [Ads 20202 - Revise Existing 'Edit Line Items Component'
    @                 To copy all at once instead of in the loop  
    @ Param:        Map<String,String> mapQli2Targeting: index of QLI being created to save DML create Tareting first then assign to QLI
    @               QLI Index => TargetingId 
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.12.2020 / Vadhanak Voun / Created the method.
     @ Change history: 05.06.2021 / Sophal Noch / US-0009753 modified method to avoid creating unnessary targeting record
    *********************************************************************************************************************************/
    public static Map<Integer,String> copyProdPackageTargetingToLine(Map<String,String> mapQli2Targeting )
    {         
        Set<String> setAllQid = mapQli2Targeting.keySet();
        Set<String> setAllTarget = new Set<String>();
        Map<Id, Integer> mapSrcTarId2Qty = new Map<Id, Integer>();

        // System.debug('nsp: mapQli2Targeting.keySet() == '+mapQli2Targeting.keySet());
        // System.debug('nsp: mapQli2Targeting.values() == '+mapQli2Targeting.values());

        for(String tid : mapQli2Targeting.values())
        {

            setAllTarget.add(tid);

            Id targId = (Id)tid;
            if(!mapSrcTarId2Qty.containsKey(targId)){ // 05.06.2021 / Sophal Noch / US-0009753 map source targeting id to the first targeting qty that will be created by cloning.
                mapSrcTarId2Qty.put(targId,1);
            }else{ // 05.06.2021 / Sophal Noch / US-0009753 map source targeting id to number of targeting record that will be created by cloning
                Integer tarQty = mapSrcTarId2Qty.get(targId);
                tarQty++;
                mapSrcTarId2Qty.put(targId,tarQty);
            }

        }
        QlisTargetingCloner targetingCloner = new QlisTargetingCloner();
        targetingCloner.mapQli2Targeting = mapQli2Targeting;
        targetingCloner.srcTargetings = (List<Targeting__c>) QueryUtil.queryRecords(Util.NS+'Targeting__c',' Id IN:value1',new Map<String, Object>{'value1'=>setAllTarget});
        targetingCloner.targetQliIds = setAllQid; //num of QLI 
        targetingCloner.removeTgRecType = true;
        targetingCloner.mapSrcTarId2Qty = mapSrcTarId2Qty;

        // System.debug('nsp: targetingCloner.mapSrcTarId2Qty  == '+targetingCloner.mapSrcTarId2Qty);

        return targetingCloner.doCloneAll();
        
    }

    virtual private class TargetingCloner {
        public Map<Id, List<Targeting__c>> mOldTgId2NewRecords = new Map<Id, List<Targeting__c>>();
        public List<Targeting__c> srcTargetings { get;set;}
        public List<Targeting__c> cloneTargetings { get; set;}
        public Integer numOfEachToClone = 1; // indicate how many new targeting will be cloned from each source targeting 
        public Set<String> srcTargetingIds { get; set; }
        public boolean removeTgRecType = false;
        public Map<Id,Integer> mapSrcTarId2Qty = new Map<Id,Integer>();
        public TargetingCloner(){}
        public TargetingCloner(Set<String> srcTargetingIds) {
            if( srcTargetingIds.isEmpty() ) return;
            this.srcTargetingIds = srcTargetingIds;
            this.srcTargetings = (List<Targeting__c>) QueryUtil.queryRecords(Util.NS+'Targeting__c',srcTargetingIds);
            for(Targeting__c srcTarg : this.srcTargetings){  // 05.06.2021 / Sophal Noch / US-0009753
                mapSrcTarId2Qty.put(srcTarg.Id, 1);
            }
        }

        virtual public List<Targeting__c>  doClone(){
             return this.cloneTargetingAndAssociations(this.srcTargetings, this.numOfEachToClone, this.mapSrcTarId2Qty);
        }

        protected List<Targeting__c>  cloneTargetingAndAssociations(List<Targeting__c> srcTargetings,Integer numOfEachToClone, Map<Id,Integer> mapSrcTarId2Qty){
            if( srcTargetings.isEmpty() ) return new List<Targeting__c>();
            
            List<Targeting__c> cloneTargetings = this.cloneTargetings(srcTargetings, numOfEachToClone, mapSrcTarId2Qty);
            Set<String> setAssociationSObjects = new Set<String>
                        {Util.NS+'TargetingGeographyAssociation__c',
                        Util.NS+'TargetingKeyValueAssociation__c',
                        Util.NS+'TargetingDeviceAssociation__c',
                        Util.NS+'TargetingConnectionAssociation__c',
                        Util.NS+'TargetingFrequencyAssociation__c',
                        Util.NS+'PlacementTargetingAssociation__c',
                        Util.NS+'TargetingContentAssociation__c'};

            for(String sObjectName : setAssociationSObjects){ 

                // clone targeting associatoins
                List<sObject> listAssociationToClone = new  List<sObject>();
                for(sObject associateExisting: QueryUtil.queryRecords(sObjectName,Util.NS+'Targeting__c IN:value1', new Map<String,Object>{'value1'=>new Map<Id, Targeting__c>(srcTargetings).values()})) {
                    Id tgOldId = (Id) associateExisting.get(Util.NS+'Targeting__c');
                    //list if new targeting by src targeting base on numOfEachToClone (number of LItem)
                    for( Targeting__c desTargeting : mOldTgId2NewRecords.get(tgOldId)){
                        Id tgNewId = desTargeting.Id;
                        SObject associateNew = associateExisting.clone();
                        associateNew.put(Util.NS+'Targeting__c', tgNewId );

                        if(sObjectName.equalsIgnoreCase(Util.NS+'TargetingKeyValueAssociation__c')) {                            
                            //associateNew.put(Util.NS+'TargetKeyValue__c', tgNewId+''+associateNew.get(Util.NS+'DART_KeyValue__c')+''+associateNew.get(Util.NS+'Operator__c'));
                            //NK:06/02/2021: US-0008913
                            String kvId = associateExisting.get('GAM_Key_Value__c') <> null?associateExisting.get('GAM_Key_Value__c')+'':''; // 13.06.2025 /Sophal Noch/ US-0012504 : remove associateExisting.get('Audience_Segment__c') in order to remove GAM_Audience_Segment__c object
                            associateNew.put(Util.NS+'TargetKeyValue__c', tgNewId+''+kvId+''+associateNew.get(Util.NS+'Operator__c'));

                        } else if(sObjectName.equalsIgnoreCase(Util.NS+'TargetingDeviceAssociation__c')) {
                            associateNew.put(Util.NS+'TargetDevice__c', tgNewId+''+associateNew.get(Util.NS+'Device__c'));
                        } else if(sObjectName.equalsIgnoreCase(Util.NS+'TargetingConnectionAssociation__c')) {
                            associateNew.put(Util.NS+'TargetConnection__c', tgNewId+''+associateNew.get(Util.NS+'Connection__c'));
                        } else if(sObjectName.equalsIgnoreCase(Util.NS+'TargetingGeographyAssociation__c')) {
                            associateNew.put(Util.NS+'TargetGeography__c', tgNewId+''+associateNew.get(Util.NS+'Geography__c'));
                        } else if(sObjectName.equalsIgnoreCase(Util.NS+'TargetingContentAssociation__c')) {
                            associateNew.put(Util.NS+'Target_Content_Key__c', tgNewId+''+associateNew.get(Util.NS+'TargetingContent__c'));
                        } 

                        listAssociationToClone.add(associateNew);
                    }
                }
                //system.debug('>>>listAssociationToClone: '+listAssociationToClone);
                WithoutSharing.doInsert(listAssociationToClone);
                
            }
            return cloneTargetings;
        }

        protected List<Targeting__c> cloneTargetings(List<Targeting__c> srcTargetings, Integer numOfEachToClone, Map<Id,Integer> mapSrcTarId2Qty){
            cloneTargetings = new List<Targeting__c>();
            
            for(Targeting__c srcTargeting: srcTargetings){
                Integer numberTarToClone = mapSrcTarId2Qty.containsKey(srcTargeting.Id) ? mapSrcTarId2Qty.get(srcTargeting.Id) : 0; // 05.06.2021 / Sophal Noch / US-0009753 number of targeting records to be cloned per source targeting id
                // System.debug('nsp: numberTarToClone  == '+numberTarToClone);
                for( Integer nCloned = 0; nCloned < numberTarToClone ; nCloned ++ ){
                    Targeting__c cloneTargeting = srcTargeting.clone();
                    if(removeTgRecType) {
                        cloneTargeting.RecordTypeId = GW_Targeting.defaultTargetingRecordTypeId;
                    }

                    cloneTargetings.add(cloneTargeting);
                    if(!mOldTgId2NewRecords.containsKey(srcTargeting.Id)) mOldTgId2NewRecords.put(srcTargeting.Id,new List<Targeting__c>());
                    mOldTgId2NewRecords.get(srcTargeting.Id).add(cloneTargeting);
                }
            }
            WithoutSharing.doInsert(cloneTargetings);
            // System.debug('nsp: cloneTargetings To inset == '+cloneTargetings.size());
            return cloneTargetings;
        }
    }

    private virtual class QlisTargetingCloner extends TargetingCloner{
        //public Map<Id, Set<String>> mapQli2Targeting;
        public Map<String,String> mapQli2Targeting;

        public Set<String> targetQliIds;
        public Map<Id,Integer> mapSrcTarId2Qty = new Map<Id,Integer>();
        public QlisTargetingCloner(){}
        public QlisTargetingCloner(String srcQliId, Set<String> targetQliIds ){
            this.targetQliIds = targetQliIds;
            this.srcTargetings = (List<Targeting__c>) QueryUtil.queryRecords(Util.NS+'Targeting__c',' Id IN (SELECT Targeting__c FROM QuoteLineItem WHERE Id =:value1 ) ',new Map<String, Object>{'value1'=>srcQliId});
            for(Targeting__c srcTarg : this.srcTargetings){ // 05.06.2021 / Sophal Noch / US-0009753
                mapSrcTarId2Qty.put(srcTarg.Id, this.targetQliIds.size());
            }
        }

        override public List<Targeting__c>  doClone(){
            this.numOfEachToClone = this.targetQliIds.size();
            this.deleteExistingTargeting(targetQliIds);
            List<Targeting__c>  cloneTargetings = this.cloneTargetingAndAssociations(this.srcTargetings, this.numOfEachToClone, this.mapSrcTarId2Qty);
            this.setTargetingIdToQuote(cloneTargetings, targetQliIds );
            return cloneTargetings;
        }

        //NK:22/12/2020: US-0008850 
        public Map<Integer,String> doCloneAll()
        {
            Map<Integer,String> mapResult = new Map<Integer,String>();
            this.numOfEachToClone = this.targetQliIds.size();
            //this.deleteExistingTargeting(targetQliIds); new QLI no related child to delete!
            List<Targeting__c>  cloneTargetings = this.cloneTargetingAndAssociations(this.srcTargetings, this.numOfEachToClone, this.mapSrcTarId2Qty);   
            List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();
            //mOldTgId2NewRecords(src targeting to list of new clone), mapQli2Targeting(QLI index -> src Targeting)
            //link QLI to new clone targeting
            for(String qliIndex : mapQli2Targeting.keySet())
            {
                String srcTarId = mapQli2Targeting.get(qliIndex);
                List<Targeting__c> listCloneTarg = mOldTgId2NewRecords.get(srcTarId); //new targetings that cloned from this src
                //same src with different clone Targeting. take 1 out to assign to QLI
                Targeting__c tar1 = listCloneTarg.remove(0);
                mapResult.put(Integer.valueOf(qliIndex),tar1.Id);                 
            }
             
            return mapResult;
        }
         
        public void setTargetingIdToQuote(List<Targeting__c> cloneTargetings, Set<String> targetQliIds){
            List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();

            for( String targetQliId : targetQliIds ) {
                Targeting__c cloneTargeting = cloneTargetings.remove(0);
                
                qlisToUpdate.add(new QuoteLineItem( Id = targetQliId, Targeting__c = cloneTargeting.Id ));

            }
            update qlisToUpdate;
        }

        public void deleteExistingTargeting(Set<String> targetQliIds){
            WithoutSharing.doDelete([SELECT id FROM Targeting__c WHERE Id IN (SELECT Targeting__c FROM QuoteLineItem WHERE Id IN:targetQliIds)]);
        }

    }

	public static void initPredefinedTargetings(QuoteLineItem qli) {
		qli.Predefined_Adunit__c = qli.Product2.PredifinedAdunit__c;
		// Predefined_DeviceCategory__c, Predefined_Placement__c need these fields?
    }
}