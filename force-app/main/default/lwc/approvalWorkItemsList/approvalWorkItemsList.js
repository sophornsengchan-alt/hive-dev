/*********************************************************************************************************************************
@ Class:        ApprovalWorkItemsList
@ Version:      1.0
@ Author:       GitHub Copilot
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09/30/2025 / GitHub Copilot / Initial creation - LWC component for displaying approval work items with GraphQL
*********************************************************************************************************************************/

import { LightningElement, wire, api, track } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import customLabels from 'c/customLabels';

export default class ApprovalWorkItemsList extends LightningElement {
    @api recordId; // Record Id passed from the record page
    @track approvalWorkItems = [];
    @track error = null;
    @track isLoading = true;
    
    // Step 1: Collect group IDs from approval work items
    @track groupIds = [];
    
    // Step 2: Collect all user IDs (from approval items + group members)
    @track userIds = [];
    
    // Maps for storing resolved names
    userMap = new Map();
    groupMap = new Map();
    groupMemberMap = new Map(); // groupId -> [userIds]
    
    // Store raw work items for final processing
    rawWorkItems = [];

    get wireVariables() {
        return { recordId: this.recordId };
    }

    get hasApprovalWorkItems() {
        return this.approvalWorkItems && this.approvalWorkItems.length > 0;
    }

    get cardTitle() {
        const count = this.approvalWorkItems ? this.approvalWorkItems.length : 0;
        return `Approval Work Items (${count})`;
    }

    // Step 1: Wire adapter for approval work items - collects group IDs
    @wire(graphql, {
        query: gql`
            query getApprovalWorkItems($recordId: ID!) {
                uiapi {
                    query {
                        ApprovalWorkItem(where: { RelatedRecordId: { eq: $recordId } }, first: 200, orderBy: { Name: { order: DESC } }) {
                            edges {
                                node {
                                    Id
                                    Name { value }
                                    ApprovalConditionName { value }
                                    Status { value }
                                    ReviewedById { value }
                                    ReviewedDate { value }
                                    AssignedToId { value }
                                    Comments { value }
                                }
                            }
                            pageInfo {
                                hasNextPage
                                endCursor
                            }
                        }
                    }
                }
            }
        `,
        variables: '$wireVariables'
    })
    wiredApprovalWorkItems({ errors, data }) {
        if (data) {
            this.processApprovalWorkItems(data);
        } else if (errors) {
            console.error('Error loading approval work items', errors);
            this.isLoading = false;
        }
    }

    // Step 2: Wire adapter for group members - collects user IDs from groups
    @wire(graphql, {
        query: gql`
            query getGroupMembersByIds($groupIds: [ID!]) {
                uiapi {
                    query {
                        GroupMember(where: { GroupId: { in: $groupIds } }, first: 2000) {
                            edges {
                                node {
                                    Id
                                    GroupId { value }
                                    UserOrGroupId { value }
                                }
                            }
                        }
                        Group(where: { Id: { in: $groupIds } }, first: 200) {
                            edges {
                                node {
                                    Id
                                    Name { value }
                                    Type { value }
                                }
                            }
                        }
                    }
                }
            }
        `,
        variables: '$memberWireVariables'
    })
    wiredGroupMembers({ errors, data }) {
        if (data && this.groupIds.length > 0) {
            this.processGroupMembersData(data);
        } else if (errors) {
            console.error('Error loading group members', errors);
            // Continue with just direct user IDs
            this.processDirectUserIds();
        } else if (this.groupIds.length === 0 && this.rawWorkItems.length > 0) {
            // No groups, process direct user IDs
            this.processDirectUserIds();
        }
    }

    // Step 3: Wire adapter for users - gets user names
    @wire(graphql, {
        query: gql`
            query getUsersByIds($userIds: [ID!]) {
                uiapi {
                    query {
                        User(where: { Id: { in: $userIds } }, first: 2000) {
                            edges {
                                node {
                                    Id
                                    Name { value }
                                }
                            }
                        }
                    }
                }
            }
        `,
        variables: '$userWireVariables'
    })
    wiredUsers({ errors, data }) {
        if (data && this.userIds.length > 0) {
            this.processUsersData(data);
        } else if (errors) {
            console.error('Error loading users', errors);
            this.finalizeWorkItems();
        } else if (this.userIds.length === 0 && this.rawWorkItems.length > 0) {
            // No users to fetch
            this.finalizeWorkItems();
        }
    }

    // Computed properties for wire variables
    get memberWireVariables() {
        return { groupIds: this.groupIds };
    }
    
    get userWireVariables() {
        return { userIds: this.userIds };
    }

    // Step 1: Process approval work items and collect group IDs
    processApprovalWorkItems(data) {
        try {
            const workItems = data.uiapi.query.ApprovalWorkItem.edges.map(edge => edge.node);
            
            // Store raw work items for later processing
            this.rawWorkItems = workItems;
            
            // Collect all group IDs from AssignedToId
            const groupIds = new Set();
            workItems.forEach(item => {
                if (item.AssignedToId?.value && item.AssignedToId.value.startsWith('00G')) {
                    groupIds.add(item.AssignedToId.value);
                }
            });
            
            this.groupIds = Array.from(groupIds);
            
            // If no groups, skip to processing direct user IDs
            if (this.groupIds.length === 0) {
                this.processDirectUserIds();
            }
            
        } catch (error) {
            this.error = 'Error processing data: ' + error.message;
            this.isLoading = false;
        }
    }

    // Step 2: Process group members and collect all user IDs
    processGroupMembersData(data) {
        try {
            // Process groups
            const groups = data.uiapi.query.Group.edges.map(edge => edge.node);
            groups.forEach(group => {
                this.groupMap.set(group.Id, group.Name.value);
            });
            
            // Process group members and collect user IDs
            const members = data.uiapi.query.GroupMember.edges.map(edge => edge.node);
            const userIdsFromGroups = new Set();
            
            members.forEach(member => {
                const groupId = member.GroupId.value;
                const memberId = member.UserOrGroupId.value;
                
                // Track group members for display purposes
                if (!this.groupMemberMap.has(groupId)) {
                    this.groupMemberMap.set(groupId, []);
                }
                
                if (memberId.startsWith('005')) { // User ID
                    userIdsFromGroups.add(memberId);
                    this.groupMemberMap.get(groupId).push(memberId);
                }
            });
            
            // Combine with direct user IDs from approval work items
            this.collectAllUserIds(userIdsFromGroups);
            
        } catch (error) {
            this.processDirectUserIds();
        }
    }

    // Helper: Process direct user IDs when no groups
    processDirectUserIds() {
        this.collectAllUserIds(new Set());
    }

    // Helper: Collect all user IDs (direct + from groups)
    collectAllUserIds(userIdsFromGroups) {
        const allUserIds = new Set(userIdsFromGroups);
        
        // Add direct user IDs from approval work items
        this.rawWorkItems.forEach(item => {
            if (item.ReviewedById?.value) {
                allUserIds.add(item.ReviewedById.value);
            }
            if (item.AssignedToId?.value && item.AssignedToId.value.startsWith('005')) {
                allUserIds.add(item.AssignedToId.value);
            }
        });
        
        this.userIds = Array.from(allUserIds);
        
        // If no users to fetch, finalize immediately
        if (this.userIds.length === 0) {
            this.finalizeWorkItems();
        }
    }

    // Step 3: Process users data
    processUsersData(data) {
        try {
            const users = data.uiapi.query.User.edges.map(edge => edge.node);
            users.forEach(user => {
                this.userMap.set(user.Id, user.Name.value);
            });
            
            this.finalizeWorkItems();
            
        } catch (error) {
            this.finalizeWorkItems();
        }
    }

    // Final step: Update work items with resolved names
    finalizeWorkItems() {
        try {
            this.approvalWorkItems = this.rawWorkItems.map(item => {
                const assignedToData = this.getAssignedToData(item.AssignedToId?.value);
                
                return {
                    Id: item.Id,
                    Name: item.Name?.value || '',
                    ApprovalConditionName: item.ApprovalConditionName?.value || '',
                    Status: item.Status?.value || '',
                    ReviewedBy: this.getNameForId(item.ReviewedById?.value),
                    AssignedTo: assignedToData.displayName,
                    AssignedToIsGroup: assignedToData.isGroup,
                    AssignedToMembers: assignedToData.members,
                    Comments: item.Comments?.value || '',
                    ReviewedDate: item.ReviewedDate?.value ? new Date(item.ReviewedDate.value).toLocaleString() : '',
                    approvalWorkItemUrl: `/lightning/r/ApprovalWorkItem/${item.Id}/view`
                };
            });
            
            this.isLoading = false;
            
        } catch (error) {
            this.error = 'Error finalizing work items: ' + error.message;
            this.isLoading = false;
        }
    }

    // Helper: Get assigned to data with group information
    getAssignedToData(id) {
        if (!id) return { displayName: '', isGroup: false, members: '' };
        
        // Check if it's a user
        if (this.userMap.has(id)) {
            return {
                displayName: this.userMap.get(id),
                isGroup: false,
                members: ''
            };
        }
        
        // Check if it's a group
        if (this.groupMap.has(id)) {
            const groupName = this.groupMap.get(id);
            let memberNames = '';
            
            // Get member names for tooltip
            if (this.groupMemberMap.has(id)) {
                const memberIds = this.groupMemberMap.get(id);
                memberNames = memberIds
                    .map(memberId => this.userMap.get(memberId))
                    .filter(name => name) // Remove any undefined names
                    .join(', ');
            }
            
            return {
                displayName: groupName,
                isGroup: true,
                members: memberNames || 'No members found'
            };
        }
        
        // Fallback to ID
        return {
            displayName: id,
            isGroup: false,
            members: ''
        };
    }

    // Helper: Get name for ID (simplified, used for ReviewedBy)
    getNameForId(id) {
        if (!id) return '';
        
        // Check users first
        if (this.userMap.has(id)) {
            return this.userMap.get(id);
        }
        
        // Check groups (without members for simple display)
        if (this.groupMap.has(id)) {
            return this.groupMap.get(id);
        }
        
        // Fallback to ID
        return id;
    }

    // Label getters for centralized label management
    get cardTitle() {
        return customLabels.ApprovalWorkItems_CardTitle;
    }

    get labels() {
        return {
            approvalWorkItemName: customLabels.ApprovalWorkItems_Column_Name,
            approvalConditionName: customLabels.ApprovalWorkItems_Column_ConditionName,
            status: customLabels.ApprovalWorkItems_Column_Status,
            reviewedBy: customLabels.ApprovalWorkItems_Column_ReviewedBy,
            assignedTo: customLabels.ApprovalWorkItems_Column_AssignedTo,
            comments: customLabels.ApprovalWorkItems_Column_Comments,
            reviewedDate: customLabels.ApprovalWorkItems_Column_ReviewedDate,
            noItemsFoundTitle: customLabels.ApprovalWorkItems_NoItemsFound_Title,
            noItemsFoundDescription: customLabels.ApprovalWorkItems_NoItemsFound_Description,
            loadingMessage: customLabels.ApprovalWorkItems_LoadingMessage
        };
    }
}