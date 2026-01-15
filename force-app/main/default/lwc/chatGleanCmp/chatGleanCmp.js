/*********************************************************************************************************************************
 * Component:       chatGleanCmp
 * Version:         1.0
 * Author:          Anujit Das, Sambath Seng, Sophal Noch
 * Purpose:         Glean AI Chat Component for eBay HIVE CRM integration - US-0033579, US-0033581, US-0033813
 * -------------------------------------------------------------------------------------------------------------------------------
 * Change history: 20.10.2025 / Sambath Seng / Created the class.
 *               : 21.10.2025 / Sophal Noch / US-0033581 - 3. Connect Glean Agent from chat component
 *               : 12.11.2025 / Sophal Noch / US-0033813 - Feedback on Glean custom chat component
 *               : 14.11.2025 / Vimean Heng / US-0033583 - 4. Display Predefined Prompts in Chat UI
 *********************************************************************************************************************************/
import { LightningElement, track, api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAgentResponse from '@salesforce/apex/GleanAgentController.getAgentResponse';
import { NavigationMixin } from 'lightning/navigation';
import isUserAuthorized from '@salesforce/apex/GleanAgentController.isUserAuthorized';
import getGleanAgentOptions from '@salesforce/apex/GleanAgentController.getGleanAgentOptions';
import getAuthUrl from '@salesforce/apex/GleanAgentController.getAuthUrl';
import getChatId from '@salesforce/apex/GleanAgentController.getChatId';
import getChatById from '@salesforce/apex/GleanAgentController.getChatById';
import getConversationStarters from '@salesforce/apex/GleanAgentController.getConversationStarters';
import customLabel from 'c/customLabels';
import chatLoading from '@salesforce/resourceUrl/chatLoading';
import hiveAssistantIcon from '@salesforce/resourceUrl/HiveAssistantIcon';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';
import USER_FIRST_NAME from '@salesforce/schema/User.FirstName';


export default class ChatGleanCmp extends NavigationMixin(LightningElement) {
    // Message input and chat state
    @track messageInput = '';
    @track chatMessages = [];
    @track currentTime = '';
    // Add user property after existing properties
    @track currentUser;
    
    // UI state management
    @track isMinimized = false;
    @track isFullScreenMode = false;
    @track isInitialLoading = true; // Initial loading state for component initialization
    @track isMessageSending = false; // New: Track message sending state without loading screen
    
    // Authentication state
    @track isGleanAuthenticated = false;
    @track authUrl = '';
    
    // Agent management
    @track agentOptions = [];
    @track selectedAgentId = '';
    // Added selectedAgentName for conversation starters
    @track selectedAgentName = '';

    @track chatId;

    @track checkChatHistoryLoad = false;

    @api showSpinner = false;
    
    //Added conversation starters functionality
    @track conversationStarters = [];
    
    // API properties for icons
    @api chatIconUrl;
    @api agentIconUrl;
    @api height;

    label = customLabel;
    
    // Private properties for popup management
    popup = null;
    interval = null;

    chatLoadingUrl = chatLoading; // URL for the chat loading
    hiveIconUrl = hiveAssistantIcon; // 19.11.2025 / Hive Assistant Icon
    

     // Add wire to get current user data
    @wire(getRecord, { recordId: USER_ID, fields: [USER_NAME, USER_FIRST_NAME] })
    wiredUser({ error, data }) {
        if (data) {
            this.currentUser = data;
        } else if (error) {
            console.error('Error fetching user data:', error);
        }
    }

    /**
     * Component initialization - Check authentication status and load agents
     */
    async connectedCallback() {
        try {
            this.updateCurrentTime();
            await this.initializeComponent();
        } catch (error) {
            this.handleInitializationError(error);
        } finally {
            this.isInitialLoading = false;
        }
    }

    renderedCallback() {
        this.scrollAfterChatHistoryLoad(); // 12.11.2025 / Sophal Noch / US-0033813 : call after chat history load
    }

    scrollAfterChatHistoryLoad() { 
        if(this.checkChatHistoryLoad){ // only load once wwhen chat history is loaded
            const customMessages = this.template.querySelectorAll('.custom-message');
            if(customMessages && customMessages.length === this.chatMessages.length){
                this.scrollToBottom(); // scroll to the bottom of the page after chat history load
                this.checkChatHistoryLoad = false;
            }
        }
    }

    /**
     * Initialize component by checking authorization and loading agents
     */
    async initializeComponent() {
        const [authUrl, isAuthorized] = await Promise.all([
            getAuthUrl(),
            isUserAuthorized()
        ]);
        
        this.authUrl = authUrl;
        this.isGleanAuthenticated = isAuthorized;
        
        if (isAuthorized) {
            this.chatId = await getChatId(); // 12.11.2025 / Sophal Noch / US-0033813 : get chatId from User record
            await this.loadAgents();
            this.addInitialGreeting();
        }
    }


    /**
     * @description Handle initialization errors and provide user feedback
     * @param {Error} error - The initialization error that occurred
     */
    handleInitializationError(error) {
        this.showToast('Error', this.label.Glean_Error_Initialize_Chat_Component, 'error');
    }

    /**
     * Add initial greeting message to chat
     */
    /*addInitialGreeting() {
        this.chatMessages.push({
            id: 'agent-greeting',
            text: this.label.Glean_Msg_Initial_Greeting,
            isAgent: true,
            messageClass: 'slds-chat-listitem slds-chat-listitem_inbound',
            textClass: 'slds-chat-message__text slds-chat-message__text_inbound slds-theme_shade slds-var-p-around_small slds-var-m-bottom_small slds-grid slds-grid_align-center'
        });
        }*/
    
    /**
     * Add initial greeting message to chat with personalized user name
     */
    addInitialGreeting() {
        // Get the user's first name, fallback to full name or generic greeting
        let userName = 'there'; // Default fallback
        
        if (this.currentUser) {
            userName = getFieldValue(this.currentUser, USER_FIRST_NAME) || 
                      getFieldValue(this.currentUser, USER_NAME) || 
                      'there';
        }
        
        // Replace {0} with the actual user first name
        const personalizedGreeting = this.label.Glean_Msg_Initial_Greeting.replace('{0}', userName);
        
        this.chatMessages.push({
            id: 'agent-greeting',
            text: personalizedGreeting,
            isAgent: true,
            messageClass: 'slds-chat-listitem slds-chat-listitem_inbound',
            textClass: 'slds-chat-message__text slds-chat-message__text_inbound slds-theme_shade slds-var-p-around_small slds-var-m-bottom_small slds-grid slds-grid_align-center'
        });
    }

    /**
     * Load available agents from server
     */
    async loadAgents() {
        try {

            if(this.chatId){ // 12.11.2025 / Sophal Noch / US-0033813 : if there is chatId, load chat history
                this.showSpinner = true;
                const listChatItem = await getChatById({ chatId: this.chatId });
                this.populateChatHistory(listChatItem);
                this.checkChatHistoryLoad = true;
                this.showSpinner = false;
            }

            const agentData = await getGleanAgentOptions();
            
            if (!agentData || agentData.length === 0) {
                this.showToast('Warning', this.label.Glean_Warning_No_Agent_Configured, 'warning');
                this.setDefaultAgent();
                return;
            }

            this.agentOptions = agentData.map(agent => ({
                label: agent.label,
                value: agent.value,
                isDefault: agent.isDefault // Include isDefault property
            }));
            
            this.setSelectedAgent(agentData);
            
        } catch (error) {
            this.showToast('Error', this.label.Glean_Error_Failed_To_Load_Agent, 'error');
            this.setDefaultAgent();
        }
    }

    /**
     * 14.11.2025 / Vimean Heng / US-0033583
     * Set the selected agent from loaded data - prioritize default agent
     * Updated to track agent name and load conversation starters
     */
    setSelectedAgent(agentData) {
        // First, try to find and select the default agent
        const defaultAgent = agentData.find(agent => agent.isDefault === true);
        
        if (defaultAgent) {
            this.selectedAgentId = defaultAgent.value;
            this.selectedAgentName = defaultAgent.label.replace(' (Default)', '');
            this.loadConversationStarters();
        } else if (agentData.length > 0) {
            // Fallback to first agent if no default is found
            this.selectedAgentId = agentData[0].value;
            this.selectedAgentName = agentData[0].label.replace(' (Default)', '');
            this.loadConversationStarters();
        } else {
            // Last resort fallback
            this.setDefaultAgent();
        }
    }

    populateChatHistory(listChatItem){ // 12.11.2025 / Sophal Noch / US-0033813 : action that load chat history
        if(listChatItem && listChatItem.length > 0){
            listChatItem.forEach(chatItem => {
                    if(chatItem.isUser){
                        this.addUserMessage(chatItem.message);
                    } else {
                        this.addAgentMessage(chatItem.message);
                    }
            });
        }
    }

    /**
     * Set fallback default agent when no agents are available
     */
    setDefaultAgent() {
        this.agentOptions = [
            { label: this.label.Glean_Const_Hive_Assistant + ' '+ this.label.Glean_Const_Default, value: this.label.Glean_Value_Hive_Default, isDefault: true }
        ];
        this.selectedAgentId = this.label.Glean_Value_Hive_Default;
    }

    /**
     * 14.11.2025 / Vimean Heng / US-0033583
     * Handle agent selection change - Show toast instead of chat message
     * Updated to load conversation starters on agent change
     */
    handleAgentChange(event) {
        const newAgentId = event.detail.value;
        
        if (!newAgentId || newAgentId.trim() === '') {
            this.showToast('Error', this.label.Glean_Error_Select_A_Valid_Agent, 'error');
            return;
        }

        const selectedAgent = this.agentOptions.find(agent => agent.value === newAgentId);
        if (!selectedAgent) {
            this.showToast('Error', this.label.Glean_Error_Selected_Agent_Not_Found, 'error');
            return;
        }

        this.selectedAgentId = newAgentId;
        const agentName = selectedAgent.label.replace(' '+this.label.Glean_Const_Default, '');
        //Store agent name and reload conversation starters
        this.selectedAgentName = agentName;
        this.loadConversationStarters();
        this.showToast('Success', this.label.Glean_Const_Switch_Agent.replace('{0}', agentName), 'success');
    }

    /**
     * Handle authorization process
     */
    async handleAuthorize() {
        if (!this.authUrl) {
            this.showToast('Error', this.label.Glean_Error_Authorize_URL_Not_Available, 'error');
            return;
        }

        this.isInitialLoading = true;

        try {
            await this.openAuthorizationPopup();
        } catch (error) {
            this.showToast('Error', this.label.Glean_Error_Authorization_Failed, 'error');
        } finally {
            this.isInitialLoading = false;
        }
    }

    /**
     * Open authorization popup and monitor completion
     */
    async openAuthorizationPopup() {
        this.popup = window.open(this.authUrl, 'oauthPopup', 'width=600,height=700,left=200,top=100');
        
        if (!this.popup) {
            this.showToast('Error', this.label.Glean_Error_Popup_Blocked_By_Browser, 'error');
            return;
        }

        new Promise((resolve, reject) => {
            const timeout = setTimeout(() => {
                this.showToast('Error', this.label.Glean_Error_Authorization_Timeout_After_5_Mins, 'error');
                this.closePopup();
                reject(new Error('Authorization timeout'));
            }, 300000); // 5 minutes

            this.interval = setInterval(async () => {
                try {
                    if (this.popup.closed) {
                        this.showToast('Error', this.label.Glean_Error_Authorization_Windows_Was_Closed, 'error');
                        this.clearInterval();
                        clearTimeout(timeout);
                        //reject(new Error('Popup closed'));
                        return;
                    }

                    const isAuthorized = await isUserAuthorized();
                    
                    if (isAuthorized === true) {
                        this.isGleanAuthenticated = true;
                        this.chatId = await getChatId(); // 12.11.2025 / Sophal Noch / US-0033813 : get chatId from User record
                        await this.loadAgents();
                        this.addInitialGreeting();
                        this.showToast('Success', this.label.Glean_Msg_Successfully_Authorized, 'success');
                        this.closePopup();
                        clearTimeout(timeout);
                        resolve();
                    }
                } catch (err) {
                    this.showToast('Error', this.label.Glean_Error_Checking_Authorizied_Status, 'error');
                    this.closePopup();
                    clearTimeout(timeout);
                    reject(err);
                }
            }, 2000); // Check every 2 seconds
        });
    }

    /**
     * Close authorization popup and cleanup
     */
    closePopup() {
        if (this.popup && !this.popup.closed) {
            this.popup.close();
        }
        this.clearInterval();
    }

    /**
     * Clear authorization check interval
     */
    clearInterval() {
        if (this.interval) {
            clearInterval(this.interval);
            this.interval = null;
        }
    }

    /**
     * @description Handle sending chat messages with security validation - SFHIVE Security Requirement
     * @async
     */
    async handleSendMessage() {
        if (!this.messageInput || !this.messageInput.trim()) {
            this.showToast('Error', this.label.Glean_Error_Enter_Message_Before_Sending, 'error');
            return;
        }

        const userMessage = this.messageInput;
        this.addUserMessage(userMessage);
        this.messageInput = '';
        this.isMessageSending = true; // Track sending state without loading screen

        try {
            this.addChatLoading();
            const agentResponse = await getAgentResponse({agentId : this.selectedAgentId, userMessage: userMessage, chatId : this.chatId });
            this.chatId = agentResponse?.chatId ?  agentResponse.chatId : this.chatId;
            this.addAgentMessage(
                agentResponse?.responseText || this.label.Glean_Error_Recieved_Msg_Unable_To_Respond,
                agentResponse?.attachmentTitle,
                agentResponse?.attachmentUrl
            );
        } catch (error) {
            this.addAgentMessage(this.label.Glean_Error_Could_Not_Get_Response);
        } finally {
            this.removeChatLoading();
            this.isMessageSending = false;
            this.scrollToBottom();
        }
    }

    /**
     * Add user message to chat history
     */
    addUserMessage(message) {
        this.chatMessages.push({
            id: 'user-msg-' + Date.now(),
            text: message,
            isAgent: false,
            messageClass: 'slds-chat-listitem slds-chat-listitem_outbound',
            textClass: 'slds-chat-message__text slds-chat-message__text_outbound slds-theme_alt-inverse slds-var-p-around_small slds-var-m-bottom_small'
        });
        this.scrollToBottom();
    }

    /**
     * Add agent message to chat history
     */
    addAgentMessage(message, attachmentTitle = null, attachmentUrl = null) {

        message = this.buildAgentResponseTable(message); // 12.11.2025 / Sophal Noch / US-0033813 : build table from agent response
        message = this.buildAgentResponseLink(message); // 12.11.2025 / Sophal Noch / US-0033813 : build <a> tag from agent response
        message = this.buildGleanResponseParagraph(message); // 12.11.2025 / Sophal Noch / US-0033813 : build paragraph like bullet list, heading, bold, italics from agent response

        this.chatMessages.push({
            id: 'agent-response-' + Date.now(),
            text: message,
            isAgent: true,
            messageClass: 'slds-chat-listitem slds-chat-listitem_inbound',
            textClass: 'slds-chat-message__text slds-chat-message__text_inbound slds-theme_shade slds-var-p-around_small slds-var-m-bottom_small slds-grid slds-grid_align-center',
            attachmentTitle: attachmentTitle,
            attachmentUrl: attachmentUrl
        });
    }
    
    // ========================================
    // 14.11.2025 / Vimean Heng / US-0033583
    // ========================================

    /**
     * Load conversation starters from custom metadata for selected agent
     * 14.11.2025 / Fetch conversation starters based on agent name
     */
    loadConversationStarters() {
        if (!this.selectedAgentName) {
            this.conversationStarters = [];
            return;
        }

        getConversationStarters({ agentName: this.selectedAgentName })
            .then(result => {
                this.conversationStarters = result || [];
            })
            .catch(error => {
                console.error('Error loading conversation starters:', error);
                this.conversationStarters = [];
            });
    }

    /**
     * 14.11.2025 / Vimean Heng / US-0033583
     * Handle conversation starter button click
     * 14.11.2025 / Send starter as user message
     */
    handleConversationStarter(event) {
        const starterText = event.target.dataset.starter;
        if (starterText) {
            this.messageInput = starterText;
            this.handleSendMessage();
        }
    }

    /**
     * 14.11.2025 / Vimean Heng / US-0033583
     * Handle New Chat button click
     * 14.11.2025 / Reset chat and reload conversation starters
     */
    handleNewChat() {
        // Reset chat state
        this.chatMessages = [];
        this.chatId = null;
        this.messageInput = '';
        
        // Re-add the initial greeting message
        this.addInitialGreeting();
        
        // Reload conversation starters for current agent
        this.loadConversationStarters();
        
        this.showToast('Success', 'New chat started', 'success');
    }

    /**
     * 14.11.2025 / Vimean Heng / US-0033583
     * Determine if conversation starters should be shown
     * 14.11.2025 / Show starters only when authenticated, no user messages sent, and starters available
     */
    get showConversationStarters() {
        // Show starters if authenticated, have starters, and either no messages or only the initial greeting
        return this.isGleanAuthenticated && 
               this.conversationStarters.length > 0 &&
               (this.chatMessages.length === 0 || 
                (this.chatMessages.length === 1 && this.chatMessages[0].id === 'agent-greeting'));
    }

    // ========================================
    // End of Conversation Starters & New Chat functionality
    // ========================================
    
    /**
     * @description Build HTML table from markdown with XSS protection - SECURITY CRITICAL
     * @param {string} message - The message containing markdown table syntax
     * @returns {string} The message with sanitized HTML tables
     */
    buildAgentResponseTable(message) {
        // 12.11.2025 / Sophal Noch / US-0033813 : build table

        if (!message || typeof message !== 'string') {
            return '';
        }

        // Step 1: decode table markers and line breaks
        message = message
            .replace(/&#124;/g, '|')
            .replace(/\\n/g, '\n')
            .trim();

        // Step 2: find table lines
        const tableLines = message.match(/\|.*\|/g);
        if (tableLines && tableLines.length > 0) {
            const rows = tableLines
                // remove markdown separator (---)
                .filter(line => !/^(\|\s*-+\s*)+\|$/.test(line))
                .map((line, index) => {
                    const cells = line.split('|').filter(c => c.trim() !== '');
                    const isHeader = index === 0;
                    // CRITICAL: Sanitize each cell to prevent XSS - SFHIVE Security Requirement
                    if (isHeader) {
                        return `<tr style="background-color: #000000;">${cells.map(c => `<th style="background-color: #000000; color: #ffffff; border: 1px solid #808080; padding: 12px 16px; font-size: 14px; font-weight: 600; text-align: left; line-height: 1.6; vertical-align: top;">${this.sanitizeHtml(c.trim())}</th>`).join('')}</tr>`;
                    } else {
                        return `<tr style="background-color: #000000;">${cells.map(c => `<td style="background-color: #000000; color: #ffffff; border: 1px solid #808080; padding: 12px 16px; font-size: 14px; line-height: 1.6; vertical-align: top;">${this.sanitizeHtml(c.trim())}</td>`).join('')}</tr>`;
                    }
                });

            const tableHtml = `<div style="overflow-x: auto; max-width: 100%;"><table style="width: 100%; border-collapse: collapse; background-color: #000000; color: #ffffff; border: 1px solid #808080; margin: 1rem 0;">
                        ${rows.join('')}</table></div>`;

            // Replace the original markdown table with sanitized HTML table
            message = message.replace(/\|.*\|/gs, tableHtml);
        }

        return message;
    }

    /**
     * @description Build HTML links from markdown with XSS protection - SECURITY CRITICAL
     * @param {string} message - The message containing markdown link syntax
     * @returns {string} The message with sanitized HTML links
     */
    buildAgentResponseLink(message) {
        // 12.11.2025 / Sophal Noch / US-0033813 : build <a> tag
        if (!message || typeof message !== 'string') {
            return '';
        }

        // Convert image markdown ![label](url) to <a> tag with sanitization
        message = message.replace(/!\[(.*?)\]\((.*?)\)/g, (match, label, url) => {
            // CRITICAL: Sanitize URL and label to prevent XSS - SFHIVE Security Requirement
            return `<a href="${this.sanitizeUrl(url)}" target="_blank" rel="noopener noreferrer" style="color: #0176d3; text-decoration: underline;">${this.sanitizeHtml(label)}</a>`;
        });
        
        // Convert regular link markdown [label](url) to <a> tag with sanitization
        message = message.replace(/\[(.*?)\]\((.*?)\)/g, (match, label, url) => {
            // CRITICAL: Sanitize URL and label to prevent XSS - SFHIVE Security Requirement
            return `<a href="${this.sanitizeUrl(url)}" target="_blank" rel="noopener noreferrer" style="color: #0176d3; text-decoration: underline;">${this.sanitizeHtml(label)}</a>`;
        });
        
        // Enhanced: Convert plain URLs to clickable links
        message = message.replace(/(https?:\/\/[^\s<>"']+)/gi, (match, url) => {
            // CRITICAL: Sanitize URL to prevent XSS - SFHIVE Security Requirement
            const sanitizedUrl = this.sanitizeUrl(url);
            if (sanitizedUrl !== '#') {
                return `<a href="${sanitizedUrl}" target="_blank" rel="noopener noreferrer" style="color: #0176d3; text-decoration: underline;">${this.sanitizeHtml(url)}</a>`;
            }
            return match;
        });
        
        return message;
    }

    buildGleanResponseParagraph(message) {

        // 12.11.2025 / Sophal Noch / US-0033813 : build paragraph formatting

        // transform glean response message text into html with paragraphs, headings, bold, italics, and bullet lists
        if (!message) return '';

        let html = message;

        // 1️ Convert headings (### -> <h3>, ## -> <h2>, # -> <h1>)
        html = html.replace(/^###### (.*)$/gm, '<h6>$1</h6>');
        html = html.replace(/^##### (.*)$/gm, '<h5>$1</h5>');
        html = html.replace(/^#### (.*)$/gm, '<h4>$1</h4>');
        html = html.replace(/^### (.*)$/gm, '<h3>$1</h3>');
        html = html.replace(/^## (.*)$/gm, '<h2>$1</h2>');
        html = html.replace(/^# (.*)$/gm, '<h1>$1</h1>');

        // 2️ Bold and italic
        html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
        html = html.replace(/\*(.*?)\*/g, '<em>$1</em>');

        // 3️ Two-level bullet list support
        const lines = html.split('\n');
        const processed = [];
        let inList = false;
        let inSubList = false;

        for (let line of lines) {
            if (/^\s*-\s+/.test(line) && !/^\s{2,}-\s+/.test(line)) {
                if (!inList) {
                    processed.push('<ul>');
                    inList = true;
                }
                if (inSubList) {
                    processed.push('</ul>');
                    inSubList = false;
                }
                processed.push('<li>' + line.replace(/^\s*-\s+/, '') + '</li>');
            } else if (/^\s{2,}-\s+/.test(line)) {
                if (!inSubList) {
                    processed.push('<ul>');
                    inSubList = true;
                }
                processed.push('<li>' + line.replace(/^\s{2,}-\s+/, '') + '</li>');
            } else {
                if (inSubList) {
                    processed.push('</ul>');
                    inSubList = false;
                }
                if (inList) {
                    processed.push('</ul>');
                    inList = false;
                }
                processed.push(line);
            }
        }

        if (inSubList) processed.push('</ul>');
        if (inList) processed.push('</ul>');

        // 4 Replace blank lines with paragraph spacing
        html = processed.join('\n').replace(/\n{2,}/g, '<p></p>').replace(/\n/g, '<br>');

        return html;
    }

    /**
     * @description SECURITY CRITICAL - Sanitize HTML content to prevent XSS attacks
     * This method is required by SFHIVE security standards
     * @param {string} content - The content to sanitize
     * @returns {string} The sanitized content safe for HTML rendering
     * @private
     */
    sanitizeHtml(content) {
        if (!content || typeof content !== 'string') {
            return '';
        }
        // HTML entity encoding to prevent XSS - SFHIVE Security Requirement
        return content
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#x27;')
            .replace(/\//g, '&#x2F;');
    }

    /**
     * @description SECURITY CRITICAL - Sanitize URL to prevent malicious protocols
     * This method is required by SFHIVE security standards
     * @param {string} url - The URL to sanitize
     * @returns {string} The sanitized URL safe for href attributes
     * @private
     */
    sanitizeUrl(url) {
        if (!url || typeof url !== 'string') {
            return '#';
        }
        // Allow only safe protocols - SFHIVE Security Requirement
        const allowedProtocols = /^(https?|mailto):/i;
        const trimmedUrl = url.trim();
        return allowedProtocols.test(trimmedUrl) ? trimmedUrl : '#';
    }

    /**
     * @description Scroll chat to bottom - LWC Compatible
     */
    scrollToBottom() {
        Promise.resolve().then(() => {
            const scrollableDiv = this.template.querySelector('.chat-history-scrollable');
            if (scrollableDiv) {
                scrollableDiv.scrollTop = scrollableDiv.scrollHeight;
            }
        });
    }

    /**
     * Update current time display
     */
    updateCurrentTime() {
        const now = new Date();
        const hours = now.getHours();
        const minutes = now.getMinutes();
        const ampm = hours >= 12 ? 'pm' : 'am';
        const formattedHours = hours % 12 === 0 ? 12 : hours % 12;
        const formattedMinutes = minutes < 10 ? '0' + minutes : minutes;
        this.currentTime = `${formattedHours}:${formattedMinutes} ${ampm}`;
    }

    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    // Event Handlers
    handleInputChange(event) {
        this.messageInput = event.target.value;
    }

    handleInputKeyDown(event) {
        if (event.key === 'Enter') {
            this.handleSendMessage();
        }
    }

    /**
     * Handle attachment link click - Opens URL in new tab
     * 08.12.2025 / System / Added to fix link opening issue
     */
    handleAttachmentClick(event) {
        const url = event.currentTarget.dataset.url;
        if (url) {
            window.open(url, '_blank', 'noopener,noreferrer');
        }
    }

    // Computed Properties
    get computedCardClass() {
        return 'custom-chat-window';
    }

    // Check if message input should be disabled
    get isInputDisabled() {
        return this.isMessageSending;
    }

    addChatLoading(){
        this.chatMessages.push({
        id: 'agent-response-' + Date.now(),
        text: '',
        isAgent: true,
        isLoading: true,
        messageClass: 'slds-chat-listitem slds-chat-listitem_inbound',
        textClass: 'slds-chat-message__text slds-chat-message__text_inbound slds-theme_shade slds-var-p-around_small slds-var-m-bottom_small slds-grid slds-grid_align-center'
        });
    }

    removeChatLoading(){
        if(this.chatMessages.length > 0){
            const loadingMessageIndex = this.chatMessages.findIndex(msg => msg.isLoading);
            if(loadingMessageIndex !== -1){
                this.chatMessages.splice(loadingMessageIndex, 1);
            }
        }
    }

    get labelHowCan(){
        return this.label.Glean_Msg_How_Can_Hive_Assistant_Help.split("{0}")[0];
    }

    get labelHelp(){
        return this.label.Glean_Msg_How_Can_Hive_Assistant_Help.split("{0}")[1];
    }

    get labelMessageHiveAssistant(){
        return this.label.Glean_Const_Message + ' ' + this.label.Glean_Const_Hive_Assistant;
    }

    get labelAuthorizeHiveAssistant(){
        return this.label.Glean_Const_Authorize + ' ' + this.label.Glean_Const_Hive_Assistant;
    }

    // Custom message class methods for standalone UI
    get customMessageClass() {
        return 'custom-message-wrapper';
    }

    // Update chat messages to use custom classes
    get processedChatMessages() {
        return this.chatMessages.map(msg => ({
            ...msg,
            customMessageClass: msg.isAgent ? 'agent-message-wrapper' : 'user-message-wrapper',
            customTextClass: msg.isAgent ? 'custom-agent-message' : 'custom-user-message'
        }));
    }
}