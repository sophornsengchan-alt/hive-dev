/*********************************************************************************************************************************
 * Component:       accountGleanSummary
 * Version:         1.0
 * Author:          AI Assistant
 * Purpose:         Account Summary using Glean AI Agent - Display account summary on Account record page
 * -------------------------------------------------------------------------------------------------------------------------------
 * Change history: 01.12.2025 / AI Assistant / Created component for Account summary
 *********************************************************************************************************************************/
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

// Import Apex methods
import getAccountSummary from '@salesforce/apex/GleanAgentController.getAccountSummary';
import isUserAuthorized from '@salesforce/apex/GleanAgentController.isUserAuthorized';
import getAuthUrl from '@salesforce/apex/GleanAgentController.getAuthUrl';

// Import Account fields
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ORACLE_ID_FIELD from '@salesforce/schema/Account.EBH_OracleID__c';

// Import custom labels and resources
import customLabel from 'c/customLabels';
import chatLoading from '@salesforce/resourceUrl/chatLoading';

const ACCOUNT_FIELDS = [ACCOUNT_NAME_FIELD, ORACLE_ID_FIELD];

export default class AccountGleanSummary extends NavigationMixin(LightningElement) {
    @api recordId; // Account record ID from page context
    
    @track isLoading = true;
    @track isAuthenticated = false;
    @track isSummaryLoading = false;
    @track showSummary = false;
    @track summaryText = '';
    @track accountName = '';
    @track oracleId = '';
    @track authUrl = '';
    
    label = customLabel;
    chatLoadingUrl = chatLoading;
    
    // Private properties for popup management
    popup = null;
    interval = null;

    /**
     * Wire to get Account record data
     */
    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountName = getFieldValue(data, ACCOUNT_NAME_FIELD);
            this.oracleId = getFieldValue(data, ORACLE_ID_FIELD) || '';
        } else if (error) {
            console.error('Error fetching account data:', error);
            this.showToast('Error', 'Unable to load account information', 'error');
        }
    }

    /**
     * Component initialization
     */
    async connectedCallback() {
        try {
            await this.initializeComponent();
        } catch (error) {
            console.error('Initialization error:', error);
            this.showToast('Error', this.label.Glean_Error_Initialize_Chat_Component, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Initialize component - check authentication
     */
    async initializeComponent() {
        const [authUrl, isAuthorized] = await Promise.all([
            getAuthUrl(),
            isUserAuthorized()
        ]);
        
        this.authUrl = authUrl;
        this.isAuthenticated = isAuthorized;
    }

    /**
     * Handle authorization
     */
    async handleAuthorize() {
        if (!this.authUrl) {
            this.showToast('Error', this.label.Glean_Error_Authorize_URL_Not_Available, 'error');
            return;
        }

        this.isLoading = true;

        try {
            await this.openAuthorizationPopup();
        } catch (error) {
            console.error('Authorization error:', error);
            this.showToast('Error', this.label.Glean_Error_Authorization_Failed, 'error');
        } finally {
            this.isLoading = false;
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

        return new Promise((resolve, reject) => {
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
                        return;
                    }

                    const isAuthorized = await isUserAuthorized();
                    
                    if (isAuthorized === true) {
                        this.isAuthenticated = true;
                        this.showToast('Success', this.label.Glean_Msg_Successfully_Authorized, 'success');
                        this.closePopup();
                        clearTimeout(timeout);
                        resolve();
                    }
                } catch (err) {
                    console.error('Auth check error:', err);
                    this.showToast('Error', this.label.Glean_Error_Checking_Authorizied_Status, 'error');
                    this.closePopup();
                    clearTimeout(timeout);
                    reject(err);
                }
            }, 2000); // Check every 2 seconds
        });
    }

    /**
     * Close authorization popup
     */
    closePopup() {
        if (this.popup && !this.popup.closed) {
            this.popup.close();
        }
        this.clearInterval();
    }

    /**
     * Clear interval
     */
    clearInterval() {
        if (this.interval) {
            clearInterval(this.interval);
            this.interval = null;
        }
    }

    /**
     * Handle Get Summary button click
     */
    async handleGetSummary() {
        if (!this.accountName) {
            this.showToast('Error', 'Account name not available', 'error');
            return;
        }

        this.isSummaryLoading = true;
        this.showSummary = true;

        try {
            const result = await getAccountSummary({ 
                accountId: this.recordId,
                accountName: this.accountName,
                oracleId: this.oracleId || ''
            });

            if (result && result.responseText) {
                // Process the summary text similar to chat component
                this.summaryText = this.buildAgentResponseTable(result.responseText);
                this.summaryText = this.buildAgentResponseLink(this.summaryText);
                this.summaryText = this.buildGleanResponseParagraph(this.summaryText);
            } else {
                this.summaryText = this.label.Glean_Error_Could_Not_Get_Response;
                this.showToast('Warning', 'Summary generation returned empty response', 'warning');
            }
        } catch (error) {
            console.error('Error getting summary:', error);
            this.summaryText = this.label.Glean_Error_Could_Not_Get_Response;
            this.showToast('Error', 'Failed to generate account summary', 'error');
        } finally {
            this.isSummaryLoading = false;
        }
    }

    /**
     * Handle Close Summary
     */
    handleCloseSummary() {
        this.showSummary = false;
        this.summaryText = '';
    }

    /**
     * Build HTML table from markdown
     */
    buildAgentResponseTable(message) {
        if (!message || typeof message !== 'string') {
            return '';
        }

        message = message
            .replace(/&#124;/g, '|')
            .replace(/\\n/g, '\n')
            .trim();

        const tableLines = message.match(/\|.*\|/g);
        if (tableLines && tableLines.length > 0) {
            const rows = tableLines
                .filter(line => !/^(\|\s*-+\s*)+\|$/.test(line))
                .map(line => {
                    const cells = line.split('|').filter(c => c.trim() !== '');
                    return `<tr>${cells.map(c => `<td>${this.sanitizeHtml(c.trim())}</td>`).join('')}</tr>`;
                });

            const tableHtml = `<div style="overflow-x: auto; max-width: 100%;"><table class="slds-table slds-table_cell-buffer slds-table_bordered">
                        ${rows.join('')}</table></div>`;

            message = message.replace(/\|.*\|/gs, tableHtml);
        }

        return message;
    }

    /**
     * Build HTML links from markdown
     */
    buildAgentResponseLink(message) {
        if (!message || typeof message !== 'string') {
            return '';
        }

        message = message.replace(/!\[(.*?)\]\((.*?)\)/g, (match, label, url) => {
            return `<a href="${this.sanitizeUrl(url)}" target="_blank" rel="noopener noreferrer">${this.sanitizeHtml(label)}</a>`;
        });
        
        message = message.replace(/\[(.*?)\]\((.*?)\)/g, (match, label, url) => {
            return `<a href="${this.sanitizeUrl(url)}" target="_blank" rel="noopener noreferrer">${this.sanitizeHtml(label)}</a>`;
        });
        
        return message;
    }

    /**
     * Build paragraph formatting
     */
    buildGleanResponseParagraph(message) {
        if (!message) return '';

        let html = message;

        // Convert headings
        html = html.replace(/^###### (.*)$/gm, '<h6>$1</h6>');
        html = html.replace(/^##### (.*)$/gm, '<h5>$1</h5>');
        html = html.replace(/^#### (.*)$/gm, '<h4>$1</h4>');
        html = html.replace(/^### (.*)$/gm, '<h3>$1</h3>');
        html = html.replace(/^## (.*)$/gm, '<h2>$1</h2>');
        html = html.replace(/^# (.*)$/gm, '<h1>$1</h1>');

        // Bold and italic
        html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
        html = html.replace(/\*(.*?)\*/g, '<em>$1</em>');

        // Bullet lists
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

        html = processed.join('\n').replace(/\n{2,}/g, '<p></p>').replace(/\n/g, '<br>');

        return html;
    }

    /**
     * Sanitize HTML content
     */
    sanitizeHtml(content) {
        if (!content || typeof content !== 'string') {
            return '';
        }
        return content
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#x27;')
            .replace(/\//g, '&#x2F;');
    }

    /**
     * Sanitize URL
     */
    sanitizeUrl(url) {
        if (!url || typeof url !== 'string') {
            return '#';
        }
        const allowedProtocols = /^(https?|mailto):/i;
        const trimmedUrl = url.trim();
        return allowedProtocols.test(trimmedUrl) ? trimmedUrl : '#';
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

    /**
     * Computed property for authorize label
     */
    get labelAuthorizeHiveAssistant() {
        return this.label.Glean_Const_Authorize + ' ' + this.label.Glean_Const_Hive_Assistant;
    }
}