/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
 /*********************************************************************************************************************************
    @ Class:         menusController
    @ Purpose:       US-0013379 - Rework to Useful Links
    @ git Repo:      https://github.com/salesforce-experiencecloud/MultiLevelNavigationMenu
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.10.2023 / Mony Nou / Created the class.
    @                  24.09.2025 / Mony Nou / US-0033439 - CA SP - Update URL links for CA Seller Portal 
*********************************************************************************************************************************/
global with sharing class menusController {

    @AuraEnabled(cacheable=true)
    global static String getMenu(String menuId, String language, String nameFilter)
    {
        Map<String,Object> resultMap = new Map<String,Object>();
        List<treeItem> listTOCLevel1 = new List<treeItem>();

        try {
            if(Menu__c.sObjectType.getDescribe().isAccessible() && Menu_Item__c.sObjectType.getDescribe().isAccessible()
                && Schema.sObjectType.Menu__c.fields.Name.isAccessible()
                && checkMenuItemsFLSisAccessible()
            )
                {
                Boolean expanded = false;

                if(menuId == 'nameFilter')
                {
                    menuId = getMenuIdByNameFilter(nameFilter);
                }

                Map<Id,Menu_Item__c>  tocMap = queryMenu(menuId, language);

                listTOCLevel1 = populateTreeItemsByParent(tocMap, expanded);
                resultMap.put('menu',listTOCLevel1);

                //User u = [SELECT Id, Contact.Id, Account.Id, FirstName, LastName, CommunityNickname FROM User WHERE Id = :System.UserInfo.getUserId() LIMIT 1];
                String query = 'SELECT Id, Contact.Id, Account.Id, FirstName, LastName, CommunityNickname FROM User WHERE Id = :UserId';
                List<User> users = ApexSafe.query().doQuery(query, new Map<String, Object>{'UserId' => UserInfo.getUserId()});
                for (User u : users) {
                    resultMap.put('user',u);
                }
                
            } 
            else 
            {
                resultMap.put('error', 'CRUD or FLS checks failed on the Menu and/or Menu Item object(s). Please review the user\'s permissions.');
            }


        } catch(Exception e){
            resultMap.put('error',e+'');
        }

        return System.JSON.serialize(resultMap);
    }
    
    private static String getMenuIdByNameFilter(String nameFilter)
    {
        List<Menu__c> menuList = [SELECT Id FROM Menu__c WHERE Name = :nameFilter ORDER  BY CreatedDate DESC];
        return (menuList.size() > 0) ? menuList[0].Id : null ;
    }

    private static Map<Id,Menu_Item__c> queryMenu(String menuId, String language)
    {

        String spMainDomain = SEP_Helper.sepUser.domain; //MN-24092025-US-0033439: Get SP_Main_Domain__c from SEP_Helper class
        
        if (String.isBlank(spMainDomain)) { //MN-13062023-US-0013379:Keep the original behavior that get Menu/Menu Item based on User.Language

            //language = 'autoen_US' - from variable --> same value if guest, from user record if not
            if(language != null && language.trim() != '' && language.trim().startsWith('auto'))
            {
                language = language.replace('auto', '');
                language = (language != '' || System.UserInfo.getUserType() == 'Guest') ? '\'' + language + '\'' : '\'' + System.UserInfo.getLanguage() + '\',\'' + System.UserInfo.getLocale() + '\'';
            }
            //language = 'en_US' - hardcoded --> same value
            else if(language != null && language.trim() != '' && !language.trim().startsWith('auto') && language.trim() != 'none')
            {
                //language = '\'' + language + '\'';
                language = language;
            }
            //language = 'none' --> null language
            else 
            {
                language = null;
            }

        }
        
        String query = 'SELECT Id, Name, URL__c, Menu_Path__c, Open_in_New_Window__c,';
        query += 'SLDS_Icon__c, SLDS_Icon_Position__c, Menu_Item__c, Menu_Item__r.Menu_Item__c,';
        query += 'Menu_Item__r.Menu_Item__r.Menu_Item__c, Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c,';
        query += 'Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c,';
        query += 'Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c ';
        query += ' FROM Menu_Item__c WHERE ';
        query += ' Menu__c = :menuId';

        if (String.isNotBlank(spMainDomain)) { //MN-13062023-US-0013379: Enabled it to get Menu/Menu Item based on SP_Main_Domain field

            Boolean isCA = SEP_Helper.sepUser.isCARRU(); //MN-24092025-US-0033439: Check if the user is from CA RevRollup
            String revRollUp = (isCA)?SEP_Helper.sepUser.revRollUp:''; //MN-24092025-US-0033439: Get RevRollUp__c from SEP_Helper class

            //MN-24092025-US-0033439: If user is from CA RevRollup, filter by both SP_Main_Domain__c and RevRollUp__c fields
            query += ' AND (SP_Main_Domain__c = NULL OR (SP_Main_Domain__c =:spMainDomain AND RevRollUp__c =:revRollUp))';
            query += ' AND (Menu_Item__r.SP_Main_Domain__c = NULL OR (Menu_Item__r.SP_Main_Domain__c=:spMainDomain AND Menu_Item__r.RevRollUp__c =:revRollUp))';
            query += ' AND (Menu_Item__r.Menu_Item__r.SP_Main_Domain__c = NULL OR (Menu_Item__r.Menu_Item__r.SP_Main_Domain__c=:spMainDomain AND Menu_Item__r.Menu_Item__r.RevRollUp__c =:revRollUp))';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c = NULL OR (Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c=:spMainDomain AND Menu_Item__r.Menu_Item__r.Menu_Item__r.RevRollUp__c =:revRollUp))';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c = NULL OR (Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c=:spMainDomain AND Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.RevRollUp__c =:revRollUp))';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c = NULL OR (Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c=:spMainDomain AND Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.RevRollUp__c =:revRollUp))';

            /*
            query += ' AND (SP_Main_Domain__c = NULL OR SP_Main_Domain__c =:spMainDomain)';
            query += ' AND (Menu_Item__r.SP_Main_Domain__c = NULL OR Menu_Item__r.SP_Main_Domain__c=:spMainDomain)';
            query += ' AND (Menu_Item__r.Menu_Item__r.SP_Main_Domain__c = NULL OR Menu_Item__r.Menu_Item__r.SP_Main_Domain__c=:spMainDomain)';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c = NULL OR Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c=:spMainDomain)';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c = NULL OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c=:spMainDomain)';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c = NULL OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.SP_Main_Domain__c=:spMainDomain)';
            */
        }
        else if(language != null)
        {
            query += ' AND (Language__c = NULL OR Language__c includes (' + language + '))';
            query += ' AND (Menu_Item__r.Language__c = NULL OR Menu_Item__r.Language__c includes (' + language + '))';
            query += ' AND (Menu_Item__r.Menu_Item__r.Language__c = NULL OR Menu_Item__r.Menu_Item__r.Language__c includes (' + language + '))';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.Language__c = NULL OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Language__c includes (' + language + '))';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Language__c = NULL OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Language__c includes (' + language + '))';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Language__c = NULL OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Language__c includes (' + language + '))';
        }

        if(System.UserInfo.getUserType() == 'Guest')
        {
            query += ' AND Public__c = TRUE';
            query += ' AND (Menu_Item__c = NULL OR Menu_Item__r.Public__c = TRUE)';
            query += ' AND (Menu_Item__r.Menu_Item__c = NULL OR Menu_Item__r.Menu_Item__r.Public__c = TRUE)';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__c = NULL OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Public__c = TRUE)';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c = NULL OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Public__c = TRUE)';
            query += ' AND (Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c = NULL OR Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Public__c = TRUE)';
        }
        query += ' ORDER BY Menu_Path__c ASC';

        return new Map<Id, Menu_Item__c>(
        (List<Menu_Item__c>)Database.query(query)
        );
    }

    private static List<treeItem> populateTreeItemsByParent(Map<Id,Menu_Item__c> tocMap, Boolean expanded)
    {
        
        Map<String,treeItem> treeItemMapTop = new Map<String,treeItem>();
        Map<String,treeItem2> treeItemMapLevel2 = new Map<String,treeItem2>();
        Map<String,treeItem3> treeItemMapLevel3 = new Map<String,treeItem3>();
        Map<String,treeItem4> treeItemMapLevel4 = new Map<String,treeItem4>();
        Map<String,treeItem5> treeItemMapLevel5 = new Map<String,treeItem5>();
        Map<String,treeItem6> treeItemMapLevel6 = new Map<String,treeItem6>();

        for(Menu_Item__c toc : tocMap.values())
        {

            if(toc.Menu_Item__c == null) //toplevel
            {
                treeItem ti = createTreeItem(toc, expanded);
                treeItemMapTop.put(toc.Id, ti);
                
            }
            else if(toc.Menu_Item__r.Menu_Item__c == null) //1 level down
            {
                treeItem2 ti2 = createTreeItem2(toc, expanded);
                
                treeItem ti = treeItemMapTop.get(toc.Menu_Item__c);
                ti = (ti == null) ? createTreeItem(tocMap.get(toc.Menu_Item__c), expanded) : ti;
                ti.itemsMap.put(ti2.id, ti2);
                ti.items = ti.itemsMap.values();
                ti.type = (ti.items != null && ti.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItemMapTop.put(toc.Menu_Item__c, ti);
                treeItemMapLevel2.put(toc.Id,ti2);
            }
            else if(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c == null) //2 levels down
            {
                treeItem3 ti3 = createTreeItem3(toc, expanded);
                
                treeItem2 ti2 = treeItemMapLevel2.get(toc.Menu_Item__c);
                ti2 = (ti2 == null) ? createTreeItem2(tocMap.get(toc.Menu_Item__c), expanded) : ti2;
                ti2.itemsMap.put(ti3.id, ti3);
                ti2.items = ti2.itemsMap.values();
                ti2.type = (ti2.items != null && ti2.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItem ti = treeItemMapTop.get(toc.Menu_Item__r.Menu_Item__c);
                ti = (ti == null) ? createTreeItem(tocMap.get(toc.Menu_Item__r.Menu_Item__c), expanded) : ti;
                ti.itemsMap.put(ti2.id, ti2);
                ti.items = ti.itemsMap.values();
                ti.type = (ti.items != null && ti.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItemMapTop.put(toc.Menu_Item__r.Menu_Item__c, ti);
                treeItemMapLevel2.put(toc.Menu_Item__c,ti2);
                treeItemMapLevel3.put(toc.Id,ti3);
            }
            else if(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c == null) //3 levels down
            {
                treeItem4 ti4 = createTreeItem4(toc, expanded);
                
                treeItem3 ti3 = treeItemMapLevel3.get(toc.Menu_Item__c);
                ti3 = (ti3 == null) ? createTreeItem3(tocMap.get(toc.Menu_Item__c), expanded) : ti3;
                ti3.itemsMap.put(ti4.id, ti4);
                ti3.items = ti3.itemsMap.values();
                ti3.type = (ti3.items != null && ti3.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItem2 ti2 = treeItemMapLevel2.get(toc.Menu_Item__r.Menu_Item__c);
                ti2 = (ti2 == null) ? createTreeItem2(tocMap.get(toc.Menu_Item__r.Menu_Item__c), expanded) : ti2;
                ti2.itemsMap.put(ti3.id, ti3);
                ti2.items = ti2.itemsMap.values();
                ti2.type = (ti2.items != null && ti2.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItem ti = treeItemMapTop.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti = (ti == null) ? createTreeItem(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti;
                ti.itemsMap.put(ti2.id, ti2);
                ti.items = ti.itemsMap.values();
                ti.type = (ti.items != null && ti.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItemMapTop.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti);
                treeItemMapLevel2.put(toc.Menu_Item__r.Menu_Item__c, ti2);
                treeItemMapLevel3.put(toc.Menu_Item__c,ti3);
                treeItemMapLevel4.put(toc.Id,ti4);
            }
            else if(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c == null) //4 levels down
            {
                treeItem5 ti5 = createTreeItem5(toc, expanded);
                
                treeItem4 ti4 = treeItemMapLevel4.get(toc.Menu_Item__c);
                ti4 = (ti4 == null) ? createTreeItem4(tocMap.get(toc.Menu_Item__c), expanded) : ti4;
                ti4.itemsMap.put(ti5.id, ti5);
                ti4.items = ti4.itemsMap.values();
                ti4.type = (ti4.items != null && ti4.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItem3 ti3 = treeItemMapLevel3.get(toc.Menu_Item__r.Menu_Item__c);
                ti3 = (ti3 == null) ? createTreeItem3(tocMap.get(toc.Menu_Item__r.Menu_Item__c), expanded) : ti3;
                ti3.itemsMap.put(ti4.id, ti4);
                ti3.items = ti3.itemsMap.values();
                ti3.type = (ti3.items != null && ti3.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItem2 ti2 = treeItemMapLevel2.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti2 = (ti2 == null) ? createTreeItem2(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti2;
                ti2.itemsMap.put(ti3.id, ti3);
                ti2.items = ti2.itemsMap.values();
                ti2.type = (ti2.items != null && ti2.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItem ti = treeItemMapTop.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti = (ti == null) ? createTreeItem(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti;
                ti.itemsMap.put(ti2.id, ti2);
                ti.items = ti.itemsMap.values();
                ti.type = (ti.items != null && ti.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItemMapTop.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti);
                treeItemMapLevel2.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti2);
                treeItemMapLevel3.put(toc.Menu_Item__r.Menu_Item__c, ti3);
                treeItemMapLevel4.put(toc.Menu_Item__c,ti4);
                treeItemMapLevel5.put(toc.Id,ti5);
            }
            else if(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c == null) //5 levels down
            {
                treeItem6 ti6 = createTreeItem6(toc, expanded);
                
                treeItem5 ti5 = treeItemMapLevel5.get(toc.Menu_Item__c);
                ti5 = (ti5 == null) ? createTreeItem5(tocMap.get(toc.Menu_Item__c), expanded) : ti5;
                ti5.itemsMap.put(ti6.id, ti6);
                ti5.items = ti5.itemsMap.values();
                ti5.type = (ti5.items != null && ti5.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItem4 ti4 = treeItemMapLevel4.get(toc.Menu_Item__r.Menu_Item__c);
                ti4 = (ti4 == null) ? createTreeItem4(tocMap.get(toc.Menu_Item__r.Menu_Item__c), expanded) : ti4;
                ti4.itemsMap.put(ti5.id, ti5);
                ti4.items = ti4.itemsMap.values();
                ti4.type = (ti4.items != null && ti4.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItem3 ti3 = treeItemMapLevel3.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti3 = (ti3 == null) ? createTreeItem3(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti3;
                ti3.itemsMap.put(ti4.id, ti4);
                ti3.items = ti3.itemsMap.values();
                ti3.type = (ti3.items != null && ti3.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItem2 ti2 = treeItemMapLevel2.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti2 = (ti2 == null) ? createTreeItem2(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti2;
                ti2.itemsMap.put(ti3.id, ti3);
                ti2.items = ti2.itemsMap.values();
                ti2.type = (ti2.items != null && ti2.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItem ti = treeItemMapTop.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c);
                ti = (ti == null) ? createTreeItem(tocMap.get(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c), expanded) : ti;
                ti.itemsMap.put(ti2.id, ti2);
                ti.items = ti.itemsMap.values();
                ti.type = (ti.items != null && ti.items.size() > 0) ? 'SubMenuButton' : 'InternalLink';

                treeItemMapTop.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti);
                treeItemMapLevel2.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti2);
                treeItemMapLevel3.put(toc.Menu_Item__r.Menu_Item__r.Menu_Item__c, ti3);
                treeItemMapLevel4.put(toc.Menu_Item__r.Menu_Item__c, ti4);
                treeItemMapLevel5.put(toc.Menu_Item__c,ti5);
                treeItemMapLevel6.put(toc.Id,ti6);
            }

        }


        return treeItemMapTop.values();

    }

    private static treeItem createTreeItem(Menu_Item__c toc, Boolean expanded)
    {
        treeItem ti = new treeItem();
        ti.id = toc.Id;
        ti.level = 1;
        ti.label = toc.Name;
        ti.name = toc.Id;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.target = (toc.Open_in_New_Window__c) ? '_blank' : '';
        ti.expanded = expanded;
        ti.items = new List<treeItem2>();
        ti.itemsMap = new Map<String, treeItem2>();
        
        return ti;
    }

    private static treeItem2 createTreeItem2(Menu_Item__c toc, Boolean expanded)
    {
        treeItem2 ti = new treeItem2();
        ti.id = toc.Id;
        ti.level = 2;
        ti.label = toc.Name;
        ti.name = toc.Id;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.target = (toc.Open_in_New_Window__c) ? '_blank' : '';
        ti.expanded = expanded;
        ti.items = new List<treeItem3>();
        ti.itemsMap = new Map<String, treeItem3>();
        
        return ti;
    }

    private static treeItem3 createTreeItem3(Menu_Item__c toc, Boolean expanded)
    {
        treeItem3 ti = new treeItem3();
        ti.id = toc.Id;
        ti.level = 3;
        ti.label = toc.Name;
        ti.name = toc.Id;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.target = (toc.Open_in_New_Window__c) ? '_blank' : '';
        ti.expanded = expanded;
        ti.items = new List<treeItem4>();
        ti.itemsMap = new Map<String, treeItem4>();
        
        return ti;
    }

    private static treeItem4 createTreeItem4(Menu_Item__c toc, Boolean expanded)
    {
        treeItem4 ti = new treeItem4();
        ti.id = toc.Id;
        ti.level = 4;
        ti.label = toc.Name;
        ti.name = toc.Id;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.target = (toc.Open_in_New_Window__c) ? '_blank' : '';
        ti.expanded = expanded;
        ti.items = new List<treeItem5>();
        ti.itemsMap = new Map<String, treeItem5>();
        
        return ti;
    }

    private static treeItem5 createTreeItem5(Menu_Item__c toc, Boolean expanded)
    {
        treeItem5 ti = new treeItem5();
        ti.id = toc.Id;
        ti.level = 5;
        ti.label = toc.Name;
        ti.name = toc.Id;
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.target = (toc.Open_in_New_Window__c) ? '_blank' : '';
        ti.expanded = expanded;
        ti.items = new List<treeItem6>();
        ti.itemsMap = new Map<String, treeItem6>();
        
        return ti;
    }

    private static treeItem6 createTreeItem6(Menu_Item__c toc, Boolean expanded)
    {
        treeItem6 ti = new treeItem6();
        ti.id = toc.Id;
        ti.level = 6;
        ti.label = toc.Name;
        ti.name = toc.Id;
        ti.type = 'InternalLink';
        ti.icon = toc.SLDS_Icon__c;
        ti.iconPosition = toc.SLDS_Icon_Position__c;
        ti.href = toc.URL__c;
        ti.target = (toc.Open_in_New_Window__c) ? '_blank' : '';
        ti.expanded = expanded;
        
        return ti;
    }

    private static Boolean checkMenuItemsFLSisAccessible()
    {
        return (
            Schema.sObjectType.Menu_Item__c.fields.Name.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Menu__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.URL__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.SLDS_Icon__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.SLDS_Icon_Position__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Position__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Menu_Item__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Open_in_New_Window__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Public__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.Language__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.SP_Main_Domain__c.isAccessible()
            && Schema.sObjectType.Menu_Item__c.fields.RevRollUp__c.isAccessible() //MN-24092025-US-0033439: Check FLS for RevRollUp__c field
        );
    }


public class treeItem
{
    public string id;
    
    public string label;

    public string name;

    public string type;
    
    public boolean active = false;

    public string icon;

    public string iconPosition;

    public string href;

    public Integer level;

    public string target;

    public boolean expanded;

    public List<treeItem2> items;

    public Map<String, treeItem2> itemsMap;
}

public class treeItem2
{
    public string id;
    
    public string label;

    public string name;

    public string type;

    public boolean active = false;

    public string icon;

    public string iconPosition;

    public string href;

    public Integer level;

    public string target;

    public boolean expanded;

    public List<treeItem3> items;

    public Map<String, treeItem3> itemsMap;
}

public class treeItem3
{
    public string id;
    
    public string label;

    public string name;

    public string type;

    public boolean active = false;

    public string icon;

    public string iconPosition;

    public string href;

    public Integer level;

    public string target;

    public boolean expanded;

    public List<treeItem4> items;

    public Map<String, treeItem4> itemsMap;
}

public class treeItem4
{
    public string id;
    
    public string label;

    public string name;

    public string type;

    public boolean active = false;

    public string icon;

    public string iconPosition;

    public string href;

    public Integer level;

    public boolean expanded;

    public string target;

    public List<treeItem5> items;

    public Map<String, treeItem5> itemsMap;

}

public class treeItem5
{
    public string id;
    
    public string label;

    public string name;

    public string type;

    public boolean active = false;

    public string icon;

    public string iconPosition;

    public string href;

    public Integer level;

    public string target;

    public boolean expanded;

    public List<treeItem6> items;

    public Map<String, treeItem6> itemsMap;

}

public class treeItem6
{
    public string id;
    
    public string label;

    public string name;

    public string type = 'InternalLink';

    public boolean active = false;

    public string icon;

    public string iconPosition;

    public string href;

    public Integer level;

    public string target;

    public boolean expanded;

}

}