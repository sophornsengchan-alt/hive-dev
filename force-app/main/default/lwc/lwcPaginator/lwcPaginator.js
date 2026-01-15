import { LightningElement, api, track,wire } from 'lwc';
import next from '@salesforce/label/c.Next'; 
import prev from '@salesforce/label/c.Previous';
import goto from '@salesforce/label/c.GO_TO_PAGE';
export default class LwcPaginator extends LightningElement {
    label = {next, prev,goto};

    @track VISIBLE_PAGE = 4;    //4 numbe per visibile (exculded first and end)
    @track VISIBLE_PAGE_PREBACK = 1; //1 page number to click back
    @track VISIBLE_PAGE_START = 0;
    @track VISIBLE_PAGE_END = 0;

    @api numberOfRecordPerPage=25;
    @api totalPage = 0;
    @api currentPage = 1;
    @api currentPageBefore = 1;

    //to override, provide this variable as the the following object:
    //{"next":"Nächste","prev":"Vorherige","goto":"Zu Seite"}
    @api labelOverride = {};

    get allLabels()
    {
        //in case any label to override. case that uk template not to follow the user language
        if(this.labelOverride)
        {
            for (const lblName in this.labelOverride) {

                if (this.labelOverride.hasOwnProperty(lblName)) 
                {        
                    this.label[lblName] = this.labelOverride[lblName];
                }
            }
        }
        
        return this.label;
    }
    get displayPaginationLimit()
    {
        let arrPage = [];
        let curPageNew = parseInt(this.currentPage);
        
        //console.log("displayPaginationLimit ",this.currentPageBefore,curPageNew);

        let nStart=0,nEnd = 0;
        //click page number forward
        if(this.currentPageBefore <= curPageNew)
        {
            if((curPageNew +  this.VISIBLE_PAGE) < this.totalPage) 
            {
                nStart = curPageNew - this.VISIBLE_PAGE_PREBACK;
                nStart = nStart<= 1 ? 2 : nStart;
                nEnd = nStart+this.VISIBLE_PAGE ;
                nEnd = nEnd >=this.totalPage ? this.totalPage - this.VISIBLE_PAGE_PREBACK : nEnd;               

                //console.log("000000");

            }else //out of range
            {
                nEnd = curPageNew + this.VISIBLE_PAGE;
                nEnd = nEnd >= this.totalPage ? this.totalPage : nEnd;
                nStart = nEnd - this.VISIBLE_PAGE;
                nStart = nStart<= 1 ? 2 : nStart;

                nEnd = curPageNew == this.VISIBLE_PAGE ? nEnd -1 : nEnd;
                nStart = curPageNew == this.VISIBLE_PAGE? nStart-1 : nStart;

                //console.log("111111");
            }

            for(let i = nStart; i< nEnd; i++)
            {                
                arrPage.push({value : i, clsActive : (curPageNew == i?"active":"")});
                
            }
            
        }else if(this.currentPageBefore > curPageNew)   //click page number backward
        {
            nEnd = (curPageNew + 2); //< not <=
            nStart = nEnd - this.VISIBLE_PAGE;
            nStart = nStart<=1?2:nStart;
            nEnd = nStart==2?this.VISIBLE_PAGE+2:nEnd; 
            nEnd = nEnd>=this.totalPage?this.totalPage:nEnd;

            
            for(let i = nStart; i< nEnd; i++)
            {
                arrPage.push({value : i, clsActive : (curPageNew == i?"active":"")});
                
            }
        }

        //console.log("--start end>",nStart,nEnd);

        this.VISIBLE_PAGE_START = nStart;
        this.VISIBLE_PAGE_END = nEnd;

        return arrPage;
    }

   
    //to show the dots
    get hasMoreNext()
    {
        //console.log("--hasMoreNext>",this.currentPage,this.totalPage,this.VISIBLE_PAGE_END);
        return  (this.VISIBLE_PAGE_END < this.totalPage);
    }
    //to show the dots
    get hasMorePre()
    {
        return (this.currentPage == this.VISIBLE_PAGE) && ((this.VISIBLE_PAGE_START == this.VISIBLE_PAGE-1))
        || (this.currentPage == this.VISIBLE_PAGE) && ((this.VISIBLE_PAGE_START == 2))
        || (this.currentPage > this.VISIBLE_PAGE);
    }
    get firstPageNum()
    {
        return {value : 1, clsActive : (this.currentPage == 1?"active":"")};
    }
    get lastPageNum()
    {
        return {value : this.totalPage, clsActive : (this.currentPage == this.totalPage?"active":"")};
    }
    get showLast()
    {
        return this.totalPage > 1;
    }

    handleGoToInput(event)
    {
        //let val = event.detail.value; 
       
    }

    handleGotoClick(event)
    {
        let inputGTP = this.template.querySelector('.gotoInput');

        let val = parseInt(inputGTP.value);
         
        if(val > 0 )
        {
            this.currentPageBefore = this.currentPage;
            this.currentPage = val > this.totalPage ? this.totalPage : val;

            this.upateParentState();
        }
    }
    handleGoToInputKeyPress(event){
        let val = event.detail.value;
        let unicode = event.charCode || event.keyCode; 
        let inputGTP = this.template.querySelector('.gotoInput');
        let empt = (inputGTP.value==""); //first press
        
        //comma = 44 dot = 46 , e 101, k 107,  ` 96 minus 45, + 43, zero: 48
        if(unicode == 44 || unicode == 46 || unicode == 101 || unicode == 107 || unicode ==96 || unicode==45 || unicode==43 || (unicode==48 && empt))
        {
            event.preventDefault();
        }
        //Enter
        if(unicode==13)
        {
            //go to page           
            //this.currentPageBefore = this.currentPage;
            let val = parseInt(inputGTP.value);
     
            if(val > 0 )
            {
                this.currentPageBefore = this.currentPage;
                this.currentPage = val > this.totalPage ? this.totalPage : val;

                this.upateParentState();
            }

        }
        
    }
    onNextPage(){
        if(this.currentPage < this.totalPage) this.currentPage++;
        this.upateParentState();
    }
    onPrevPage() {
        if(this.currentPage > 1) this.currentPage--;
        this.upateParentState();
    }
    onChangePage(evt) {
        //.dataset.id
        var pageNumber = evt.target.dataset["id"];
        this.currentPageBefore = this.currentPage;
        this.currentPage = pageNumber;
        //console.log("onChangePage before and after: ",this.currentPageBefore,this.currentPage);

        this.upateParentState();
    }

    upateParentState()
    {
        const parentEv = new CustomEvent("updatepaginatorstate",{
            detail:{currentPage:this.currentPage}
        });
        this.dispatchEvent(parentEv);
    }
}