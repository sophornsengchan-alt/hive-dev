import { LightningElement, api, track } from 'lwc';
import fetchUserInfo from '@salesforce/apex/CustomChatterController.fetchUserInfo';
import getAllPost from '@salesforce/apex/CustomChatterController.getChatterPost';
import doPosting from '@salesforce/apex/CustomChatterController.doPosting';
import uId from '@salesforce/user/Id';
import { loadStyle, loadScript} from 'lightning/platformResourceLoader';
import customSR from '@salesforce/resourceUrl/customChatterStyle';
export default class LwcCustomChatter extends LightningElement {
    @api mdtName = "";
    @api recordId;
    @api pageName = "";
    @track allFeedItems = [];
    @track isLoadRecord = false;
    @track userId = uId;
    @track userName = "";
    @track myTextVal = "";
    @api errorMessage = "You haven't composed anything yet." ;
    @api validity = false;
    @track currentUserType = "";

    connectedCallback() {
        //console.log(">>>> load recordId:", this.recordId);
        if(this.isLoadRecord) return;
        this.isLoadRecord = true;
        if(this.pageName != "") this.findRecordId();
        this.onFetchUserInfo();
		this.loadAllRecords();
        // console.log(">>>> call back this.recordId:", this.recordId);

        // for hide header part of lightning-input-rich-text
        Promise.all([
            loadStyle(this, customSR + '/customChatterStyle.css'),
        ]).then(() => {
            // console.log("uploadstyle",result);
            })
            .catch(error => {
                console.log("error at style: ",error);
            });
	}

    findRecordId(){
        var urlString = window.location.href;
        //var baseURL = urlString.substring(0, urlString.indexOf("/s"));
        // console.log(">>>> load urlString:", urlString);
        if(urlString.includes("recordId=")){
            objParams = this.getQueryParameters();
            this.recordId = objParams["recordId"];
        } else if(urlString.includes(this.pageName)){
            var lengthObj = this.pageName.length; 
            var pathParams = urlString.substring(urlString.indexOf(this.pageName)+lengthObj, urlString.length - 1);
            var arrParams = pathParams.split("/");
            this.recordId = arrParams[0];
        }
        // console.log(">>>> load urlString this.recordId:", this.recordId);
    }

    getQueryParameters() {
        var params = {};
        var search = location.search.substring(1);
        if (search) {
            params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
                return key === "" ? value : decodeURIComponent(value)
            });
        }
        return params;
    }

    onFetchUserInfo() {
        // console.log(">>>>> recordId:", recordId );
        fetchUserInfo({})
        .then(result => {
            // console.log(">>>>> result:", result);
            if(result){
                if(result["ContactId"]) {
                    this.userId = result["ContactId"];
                    this.userName = result["Contact"]["FirstName"];
                }else{
                    this.userId = result["Id"];
                    this.userName = result["FirstName"];
                }
                this.currentUserType = result.UserType;

                var chatterPortalValue = result["PostChatterPortal__c"];
                if(chatterPortalValue != true){
                    //make user can't post
                    //hide post
                    var divblock = this.template.querySelector('[data-id="canPost"]');
                    if(divblock){
                        this.template.querySelector('[data-id="canPost"]').className='slds-hide';
                    }
                }
                // console.log(">>>>> this.userId:", this.userId);
            }
        })
        .catch(error => { 
            console.log(">>>>>first onFetchUserInfo:", error);
        }); 
    }
    
    loadAllRecords() {
        var whereCondi = "Post From eBay Seller Portal Site.%";
        var currentRecordId = this.recordId;
        if(currentRecordId) whereCondi = '%'+currentRecordId;
        else currentRecordId = whereCondi = "Post From eBay Seller Portal Site.%";

        getAllPost({ "whereCondi" : whereCondi})
        .then(result => {
            // console.log(">>>>>first load result:", result);
                var lstRec = []

                if(result && result.length > 0){
                    var resLen = result.length - 1;
                    for(var j=resLen; j>=0; j--){
                        var rec = {};
                        var titleV = '';
                        if(result[j].ParentId == this.userId){
                            titleV = 'you';
                        }else{//display post by other uName
                            var titileVal = result[j].Title;
                            var aTitle = titileVal.includes('Spliter=') ? titileVal.split('Spliter=')[1] : 'Unknown';
                            titleV = aTitle;
                        }

                        rec["container_ClassName"] = (titleV == 'you') ? "cls_container-darker" : "cls_container";
                        rec["className"] = (titleV == 'you') ? "container darker" : "container";
                        rec["title"] = "Message from " + titleV;
                        rec["value"] = result[j].Body;
                        lstRec.push(rec);
                    }
                }

                var emptyRec = {};
                emptyRec["container_ClassName"] = "cls_container";
                emptyRec["className"] = "container";
                // emptyRec["title"] = "Message from ";
                emptyRec["value"] = 'No Message.';

                if(lstRec.length === 0) lstRec.push(emptyRec);

                this.allFeedItems = lstRec;
			})
			.catch(error => { 
                console.log(">>>>>first load ERROR:", error);
			}); 
	}
    handleChangeText(event) {
        // console.log(">>>>>> :::", event.target.value);
        this.myTextVal = event.target.value;
    }

    onSendButton(event) {

        // console.log(">>>>>> Click Send :::", this.myTextVal);
        if (!this.myTextVal) {
            this.validity = false;
            this.errorMessage = "You haven't composed anything yet.";
        }else {
            if(this.myTextVal.length > 9999){
                this.validity = false;
                this.errorMessage = "You have exceeded the max length, limited 10,000 characters.";
            }else{
                this.validity = true;
            }
        }

        if(this.validity == true){

            // console.log(">>>>> recordId:", this.recordId);

            var pUserName =  this.currentUserType == 'Standard' ? 'ebay' : this.userName;
            
            var titleVal = "Post From eBay Seller Portal Site. Spliter=" + pUserName + (this.recordId == ""? "" : " Spliter=" + this.recordId );
            var feedItem = {'sobjectType': 'FeedItem', "ParentId" : this.userId, "Title" : titleVal, "Body" : this.myTextVal };

            doPosting({ postMessage : feedItem})
            .then(result => {
                // console.log(">>>>> result:", result);
                var status = result["status"];
                if(status === 'success'){
                    var temp = result["postMessage"];
                    var item = {};
                    //from you
                    item["container_ClassName"] = "cls_container-darker";
                    item["className"] = "container darker";
                    item["title"] = "Message from you";
                    item["value"] = this.myTextVal;
                    this.allFeedItems.push(item);

                    //clear text
                    this.myTextVal = '';

                    // alert("Successfully!");
                } else {
                    console.log(">>>>>post query ERROR:", error);
                    // alert("Error: " + result["message"]);
                }
                
            })
            .catch(error => { 
                console.log(">>>>>post ERROR:", error);
                // alert("Error: Something went wrong!");
            }); 
        }
    }

    get displayChatters(){
        return this.allFeedItems;
    }
}