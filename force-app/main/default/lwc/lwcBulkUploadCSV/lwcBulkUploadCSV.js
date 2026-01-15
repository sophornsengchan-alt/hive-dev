import { LightningElement, track , api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import doLoadSetting from '@salesforce/apex/ClsBulkUploadCSV.doLoadSetting';
//import doRemoveHalfCompleteDeals from '@salesforce/apex/ClsBulkUploadCSV.doClearHalfCompleteDeals';
import doSubmitMultipleDeals from '@salesforce/apex/ClsBulkUploadCSV.doSubmitMultipleDeals';
import getDealRetailCampaign from '@salesforce/apex/ClsBulkUploadCSV.getDealRetailCampaign';
import getDealOverlapDateDRC from '@salesforce/apex/ClsBulkUploadCSV.getDealOverlapDateDRC';
import getSelectedCategories from '@salesforce/apex/CustomDealController.getSelectedCategories';//Sambath Seng - 13/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category

import bulkUploadDealTemplateDE from '@salesforce/resourceUrl/SEP_Bulk_Upload_Deal_Template_DE'; //MN-14122021-US-0010945
import bulkUploadDealTemplateNA from '@salesforce/resourceUrl/SEP_Bulk_Upload_Deal_Template_NA'; //MN-14122021-US-0010945
import LWC_Valid_Specail_Character from '@salesforce/label/c.LWC_Valid_Specail_Character'; //Loumang-17-01-2022:US-0010959
// Import custom labels

import LWCBulkUploadCSVError1 from '@salesforce/label/c.LWCBulkUploadCSVError1';
import LWCBulkUploadCSVError2 from '@salesforce/label/c.LWCBulkUploadCSVError2';
import LWCBulkUploadCSVError3 from '@salesforce/label/c.LWCBulkUploadCSVError3';
import LWCBulkUploadCSVError4 from '@salesforce/label/c.LWCBulkUploadCSVError4';
import LWCBulkUploadCSVError5 from '@salesforce/label/c.LWCBulkUploadCSVError5';
import LWCBulkUploadCSVError6 from '@salesforce/label/c.LWCBulkUploadCSVError6';
import LWCBulkUploadCSVError7 from '@salesforce/label/c.LWCBulkUploadCSVError7';
import LWCBulkUploadCSVError8 from '@salesforce/label/c.LWCBulkUploadCSVError8';
import LWCBulkUploadCSVError9 from '@salesforce/label/c.LWCBulkUploadCSVError9';
import LWCBulkUploadCSVError10 from '@salesforce/label/c.LWCBulkUploadCSVError10';
import LWCBulkUploadCSVError11 from '@salesforce/label/c.LWCBulkUploadCSVError11';
import LWCBulkUploadCSVError12 from '@salesforce/label/c.LWCBulkUploadCSVError12';
import LWCBulkUploadCSVError13 from '@salesforce/label/c.LWCBulkUploadCSVError13';
import LWCBulkUploadCSVError14 from '@salesforce/label/c.LWCBulkUploadCSVError14';
import LWCBulkUploadCSVError15 from '@salesforce/label/c.LWCBulkUploadCSVError15';
import LWCBulkUploadCSVError16 from '@salesforce/label/c.LWCBulkUploadCSVError16';
import LWCBulkUploadCSVError17 from '@salesforce/label/c.LWCBulkUploadCSVError17';
import LWCBulkUploadCSVError18 from '@salesforce/label/c.LWCBulkUploadCSVError18';
import LWCBulkUploadCSVError19 from '@salesforce/label/c.LWCBulkUploadCSVError19';
import LWCBulkUploadCSVError20 from '@salesforce/label/c.LWCBulkUploadCSVError20';
import LWCBulkUploadCSVError21 from '@salesforce/label/c.LWCBulkUploadCSVError21';
import LWCBulkUploadCSVError22 from '@salesforce/label/c.LWCBulkUploadCSVError22';
import LWCBulkUploadCSVError23 from '@salesforce/label/c.LWCBulkUploadCSVError23';
import LWCBulkUploadCSVError24 from '@salesforce/label/c.LWCBulkUploadCSVError24';
import LWCBulkUploadCSVError25 from '@salesforce/label/c.LWCBulkUploadCSVError25';
import LWCBulkUploadCSVError26 from '@salesforce/label/c.LWCBulkUploadCSVError26';
import LWCBulkUploadCSVError27 from '@salesforce/label/c.LWCBulkUploadCSVError27';
import LWCBulkUploadCSVError28 from '@salesforce/label/c.LWCBulkUploadCSVError28';
import LWCBulkUploadCSVError29 from '@salesforce/label/c.LWCBulkUploadCSVError29';
import LWCBulkUploadCSVError30 from '@salesforce/label/c.LWCBulkUploadCSVError30';
import LWCBulkUploadCSVError31 from '@salesforce/label/c.LWCBulkUploadCSVError31';
import LWCBulkUploadCSVError32 from '@salesforce/label/c.LWCBulkUploadCSVError32';
import LWCBulkUploadCSVError33 from '@salesforce/label/c.LWCBulkUploadCSVError33';
import LWCBulkUploadCSVError34 from '@salesforce/label/c.LWCBulkUploadCSVError34';
import LWCBulkUploadCSVError35 from '@salesforce/label/c.LWCBulkUploadCSVError35';
import LWCBulkUploadCSVError36 from '@salesforce/label/c.LWCBulkUploadCSVError36';
import LWCBulkUploadCSVError37 from '@salesforce/label/c.LWCBulkUploadCSVError37';
import LWCBulkUploadCSVError38 from '@salesforce/label/c.LWCBulkUploadCSVError38';
import LWCBulkUploadCSVError40 from '@salesforce/label/c.LWCBulkUploadCSVError40';//Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
import Cancel from '@salesforce/label/c.lwcCancelbtn';//Loumang:12-01-2022:US-0010747


import RowNumber from '@salesforce/label/c.Row_Number';
import DealRecordsCreatedPartSuccess from '@salesforce/label/c.DealRecordsCreatedPartSuccess'

import { NavigationMixin } from 'lightning/navigation';
import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';

export default class LwcBulkUploadCSV extends NavigationMixin(LightningElement) {
    @api tabName = "";
    @api redirectToUrl = "";
    @api recordId;
    @api startDate;
    @api endDate;
    @api country;
    @api userId;
    @api availableDeal;
    @api accountId;
    @api contactId;
    @api fullContactName;
    @api numberOfDealPerPk = 150;
    @api email;
    @api labelBtnNext;
    @api labelBtnSubmit;
    @api labelBtnDownloadTemplate;
    @api labelBtnDownloadSampleFile;
    @api siteNumber;
    @api placeholder;;
    @api placeholderSite;
    @api inputLabel;
    @api inputLabelSite;
    @api lbInputFile;
    @api lbTotalRecord;
    
    label = {
        LWCBulkUploadCSVError1, LWCBulkUploadCSVError2, LWCBulkUploadCSVError3, LWCBulkUploadCSVError4, LWCBulkUploadCSVError5, 
        LWCBulkUploadCSVError6, LWCBulkUploadCSVError7, LWCBulkUploadCSVError8, LWCBulkUploadCSVError9, LWCBulkUploadCSVError10, 
        LWCBulkUploadCSVError11, LWCBulkUploadCSVError12, LWCBulkUploadCSVError13, LWCBulkUploadCSVError14, LWCBulkUploadCSVError15, 
        LWCBulkUploadCSVError16, LWCBulkUploadCSVError17, LWCBulkUploadCSVError18, LWCBulkUploadCSVError19, LWCBulkUploadCSVError20,
        LWCBulkUploadCSVError21, LWCBulkUploadCSVError22, LWCBulkUploadCSVError23, LWCBulkUploadCSVError24, LWCBulkUploadCSVError25, 
        LWCBulkUploadCSVError26, LWCBulkUploadCSVError27, LWCBulkUploadCSVError28, LWCBulkUploadCSVError29, LWCBulkUploadCSVError30, 
        LWCBulkUploadCSVError31, LWCBulkUploadCSVError32, LWCBulkUploadCSVError33, LWCBulkUploadCSVError34, LWCBulkUploadCSVError35,
        LWCBulkUploadCSVError36, LWCBulkUploadCSVError37, LWCBulkUploadCSVError38, RowNumber, DealRecordsCreatedPartSuccess,
        LWCBulkUploadCSVError40,Cancel,LWC_Valid_Specail_Character
    };

    @track totalRec = 0;
    @track existingItemIds = [];
    @track isReachLimit = false;
    @track isSomeFail = false;
    @track dealsComplete = [];
    @track dealsFailed = [];
    @track dealSaveResult = [];
    @track totalRetry= 0;
    @track maxRetry = 3;
    @track message = "";
    @track objMessageInfo = {};
    @track objMessageInfos = [];
    @track showLoadingSpinner = false;
    @track rValue = '';
    @track columns = [];
    @track currUserLang = '';
    @track mRowIndex = {};
    @track allMessageInfo = [];
    @track objMessageResult = {};
    @track isSomeError = false;
    @track drcDE = {};
    @track selectedVal = "";
    @track siteselectedVal = "";
    @track isUnableUpload = false;
    @track totalDealOfDEToday = 0;
    @track maxDEDealLimitPerDay = 500;
    @track openSeatsAvailable = 0;
    @track isDEUser = false;
    @track existingDEDealItemIds = [];

    @track defaulCols = [
                            { label: '', fieldName: 'row_number', type: 'number'},
                            { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},                       
                            { label: 'eBay Item ID', fieldName: 'EBH_eBayItemID__c', type: 'text', initialWidth: 100},
                            { label: 'Deal Price', fieldName: 'EBH_DealPrice__c', type: 'currency', initialWidth: 100, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
                            { label: 'List Price', fieldName: 'EBH_RRPWASPrice__c', type: 'currency', initialWidth: 100, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
                            { label: 'Quantity', fieldName: 'EBH_Quantity__c', type: 'number', initialWidth: 100},
                            { label: 'Maximum Purchases', fieldName: 'EBH_MaximumPurchases__c', type: 'number', initialWidth: 100},
                            { label: 'Sellers Deal Price MSKU Lower', fieldName: 'SellersDealPriceMSKULower__c', type: 'number', initialWidth: 100},
                            { label: 'Sellers Deal Price MSKU Upper', fieldName: 'SellersDealPriceMSKUUpper__c', type: 'number', initialWidth: 100},
                            { label: 'List Price MSKU Lower', fieldName: 'ListPriceMSKULower__c', type: 'number', initialWidth: 100},
                            { label: 'List Price MSKU Upper', fieldName: 'ListPriceMSKUUpper__c', type: 'number', initialWidth: 100}
                            /*{ label: 'Seller Email Address', fieldName: 'EBH_SellerEmail__c', type: 'email'}*/
                        ]; 

    @track defaulColsGerman = [
                                { label: '', fieldName: 'row_number', type: 'number'},
                                { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},
                                { label: 'eBay-Artikelnr', fieldName: 'EBH_eBayItemID__c', type: 'text', initialWidth: 100},
                                //{ label: 'Artikelbezeichnung des eBay-Angebots', fieldName: 'Item_ID_Product_Title__c', type: 'text'},
                                { label: 'Artikelbezeichnung des eBay-Angebots', fieldName: 'EBH_ProductTitle__c', type: 'text', initialWidth: 100},
                                { label: 'EAN', fieldName: 'EBH_EAN__c', type: 'text', initialWidth: 100},
                                { label: 'Artikel Zustand', fieldName: 'Item_Condition__c', type: 'text', initialWidth: 100},
                                { label: 'Artikelstückzahl für WOW! Angebot', fieldName: 'EBH_Quantity__c', type: 'text', initialWidth: 100},
                                { label: 'Angebotspreis des Verkäufers', fieldName: 'EBH_SellerPrice__c', type: 'text', initialWidth: 100},
                                //{ label: 'BISHER-Preis (UK)', fieldName: 'EBH_RRPWASPrice__c', type: 'currency'},
                                //{ label: 'BISHER-Preis (UK)_1', fieldName: 'EBH_RecommendedRetailPriceWAS__c'},
                                { label: 'Format des WOW! Angebots', fieldName: 'EBH_DealFormat__c', type: 'text', initialWidth: 100},
                                { label: 'Artikel frühestens verfügbar für WOW! Angebot ab', fieldName: 'EBH_Dealdateearliestpossible__c', type: 'text', initialWidth: 100},
                                { label: 'Preisvergleichsportal 1 (Amazon für DE)', fieldName: 'EBH_AmazonLink__c', type: 'text', initialWidth: 100},
                                { label: 'Preisvergleichsportal 2 (Idealo für DE)', fieldName: 'EBH_IdealoLink__c', type: 'text', initialWidth: 100},
                                { label: 'eBay-Hauptkategorie', fieldName: 'EBH_Category__c', type: 'text', initialWidth: 100},
                                { label: 'Kommentare des Verkäufers', fieldName: 'EBH_CommentfromSeller__c', type: 'text', initialWidth: 100}
                                //{ label: 'E-Mail des Verkäufers', fieldName: 'EBH_SellerEmail__c', type: 'text'},
                                //{ label: 'Ziel-Website für WOW! Angebot', fieldName: 'EBH_DealSiteId__c', type: 'text'},
                                
                            ]; 
    
    @track mSobjectFields = {
                                
                            };
    @track selectedSeperator = ',';
    @track data = [];
    @api deals = [];
    @track fileName = "";
    @track UploadFile = 'Upload CSV File';
    @track cmName =  'Bulk_Deal_Upload_CSV';
    @track dd_DuplicateError = "";
    @track dd_DuplicateError_display = "This deal is already subsidized for this deal period. The subsidized deal will continue as scheduled, and this unsubsidized submission has been discarded.";
    
    @track mapErrorMessages = {};
    @track displayHeaders =  [];
    //@track isFinish = false;
    @track isNoFile = true;
    selectedRecords;
    file;
    fileContent;
    fileReader;
    content;
    MAX_FILE_SIZE = 1500000;

    //@track csvStringGerman =  'eBay-Artikelnr,Artikelbezeichnung des eBay-Angebots,EAN,Artikelstückzahl für WOW! Angebot,Angebotspreis des Verkäufers,BISHER-Preis (UK),BISHER-Preis (UK)_1,Format des WOW! Angebots,Artikel frühestens verfügbar für WOW! Angebot ab,Preisvergleichsportal 1 (Amazon für DE),Preisvergleichsportal 2 (Idealo für DE),eBay-Hauptkategorie,Kommentare des Verkäufers,E-Mail des Verkäufers,Ziel-Website für WOW! Angebot\n'
    //                        + '123456789012,Product Title,10987654321,100,999,123,1999,WOW! Angebot des Tages,25/8/2016,http://amazon.com,http://idealo.com,Baby," ""Use this space to add a comment""",example@example.com,77';

    @track csvStringGerman =  'eBay-Artikelnr,Artikelbezeichnung des eBay-Angebots,EAN,Artikel Zustand,Artikelstückzahl für WOW! Angebot,Angebotspreis des Verkäufers,Format des WOW! Angebots,Artikel frühestens verfügbar für WOW! Angebot ab,Preisvergleichsportal 1 (Amazon für DE),Preisvergleichsportal 2 (Idealo für DE),eBay-Hauptkategorie,Kommentare des Verkäufers\n'
                            + '123456789012,Product Title,10987654321,Neu,100,999.00,WOW! Angebot des Tages,25/8/2030,http://amazon.com,http://idealo.com,Baby," ""Use this space to add a comment"""';
                            
    
    //                                                                 EBH_MaximumPurchases__c,SellersDealPriceMSKULower__c,SellersDealPriceMSKUUpper__c, ListPriceMSKULower__c, ListPriceMSKUUpper__c     
    @track csvString =  "ebay Item Id,Deal Price,List Price,Quantity,Maximum Purchases,Sellers Deal Price MSKU Lower,Sellers Deal Price MSKU Upper,List Price MSKU Lower,List Price MSKU Upper\n"
                    +   "xxxxxxxxxxxx,100,200,50,100,Optional,Optional,Optional,Optional";
                    // +   "100000000002,100,200,50,100,100,200,100,200\n"
                    // +   "100000000003,100,200,50,100,100,200,100,200\n"
                    // +   "100000000004,100,200,50,100,100,200,100,200\n"
                    // +   "100000000005,100,200,50,100,100,200,100,200"; 

    //@track csvHeader1  = 'ebay Item Id,Product Title,Seller Price,Deal Price,RRP,Quantity,Category';
    //@track csvHeader2  = '"ebay Item Id","Product Title","Seller Price","Deal Price","RRP","Quantity","Category"';
    @track csvHeader1  = 'ebay Item Id,Deal Price,List Price,Quantity,Maximum Purchases,Sellers Deal Price MSKU Lower,Sellers Deal Price MSKU Upper,List Price MSKU Lower,List Price MSKU Upper';
    @track csvHeader2  = '"ebay Item Id","Deal Price","List Price","Quantity","Maximum Purchases","Sellers Deal Price MSKU Lower","Sellers Deal Price MSKU Upper","List Price MSKU Lower","List Price MSKU Upper"';
    
    @track csvHeaderGerman1 = 'eBay-Artikelnr,Artikelbezeichnung des eBay-Angebots,EAN,Artikel Zustand,Artikelstückzahl für WOW! Angebot,Angebotspreis des Verkäufers,Format des WOW! Angebots,Artikel frühestens verfügbar für WOW! Angebot ab,Preisvergleichsportal 1 (Amazon für DE),Preisvergleichsportal 2 (Idealo für DE),eBay-Hauptkategorie,Kommentare des Verkäufers';
    @track csvHeaderGerman2 = '"eBay-Artikelnr","Artikelbezeichnung des eBay-Angebots","EAN","Artikel Zustand","Artikelstückzahl für WOW! Angebot","Angebotspreis des Verkäufers","Format des WOW! Angebots","Artikel frühestens verfügbar für WOW! Angebot ab","Preisvergleichsportal 1 (Amazon für DE)","Preisvergleichsportal 2 (Idealo für DE)","eBay-Hauptkategorie","Kommentare des Verkäufers"';

    //@track requiredDealFields = ["EBH_eBayItemID__c", "EBH_DealPrice__c", "List_Price__c", "EBH_Quantity__c", "EBH_MaximumPurchases__c"];                       
    @track requiredDealFields = ["EBH_eBayItemID__c", "EBH_DealPrice__c", "List_Price__c", "EBH_Quantity__c", "EBH_MaximumPurchases__c", "EBH_SellerPrice__c", "EBH_Dealdateearliestpossible__c", "EBH_ProductTitle__c"];
    @track validateFormatFields = ["EBH_eBayItemID__c", "EBH_DealPrice__c", "List_Price__c", "EBH_Quantity__c", "EBH_SellerPrice__c", "EBH_Dealdateearliestpossible__c", "EBH_ProductTitle__c", "EBH_EAN__c", "EBH_Category__c", "EBH_DealFormat__c", "Item_Condition__c", "EBH_AmazonLink__c", "EBH_IdealoLink__c"];
    @track mSiteWithCategorys = {};
    /*@track mSiteWithCategorys = {
                                    "77" : [    
                                                "Antiquitäten & Kunst", "Auto & Motorrad: Fahrzeuge","Auto & Motorrad: Teile", "Bastel- & Künstlerbedarf","Beauty & Gesundheit","Briefmarken","Bücher","Büro & Schreibwaren","Business & Industrie","Computer, Tablets & Netzwerk","Feinschmecker","Filme & DVDs","Foto & Camcorder","Garten","Garten & Terrasse","Handys & Kommunikation",
                                                "Haushaltsgeräte","Haustierbedarf","Heimwerker","Immobilien","Kleidung & Accessoires","Möbel & Wohnen","Modellbau","Münzen","Musik","Musikinstrumente","PC- & Videospiele","Reisen","Sammeln & Seltenes","Spielzeug","Tickets","TV, Video & Audio","Uhren & Schmuck","Verschiedenes","Baby","Sport"
                                            ],
                                    "3" :   [
                                                "DVDs, Films & TV", "Books, Comics & Magazines", "Business, Office & Industrial", "Cameras & Photography", "Cars, Motorcycles & Vehicles", "Clothes, Shoes & Accessories", "Coins", "Collectables", "Events Tickets", "Garden & Patio", "Holidays & Travel", "Home, Furniture & DIY", "Jewellery & Watches", "Mobile Phones & Communication", "Musical Instruments", 
                                                "Pottery, Porcelain & Glass", "Property", "Sound & Vision", "Sports Memorabilia", "Vehicle Parts & Accessories", "Wholesale & Job Lots", "Toys & Games", "Antiques", "Art", "Baby", "Computers/Tablets & Networking", "Crafts", "Dolls & Bears", "Everything Else", "Health & Beauty", "Music", "Pet Supplies", "Sporting Goods", "Stamps", "Video Games & Consoles"
                                            ],
                                    "71" :  [
                                                "Animalerie","Art, antiquités", "Auto, moto", "Bateaux, voile, nautisme", "Beauté, bien-être, parfums", "Bébé, puériculture", "Bijoux, montres", "Bricolage", "Céramiques, verres", "Collections", "DVD, cinéma", "Electroménager", "Image, son", "Immobilier", "Informatique, réseaux", "Instruments de musique", "Jardin, terrasse", 
                                                "Jeux vidéo, consoles", "Jouets et jeux", "Livres, BD, revues", "Loisirs créatifs", "Maison", "Monnaies", "Musique, CD, vinyles", "Photo, caméscopes", "PME, artisans, agriculteurs", "Sports, vacances", "Téléphonie, mobilité", "Timbres", "Véhicules: pièces, accessoires", "Vêtements, accessoires", "Vins, Gastronomie"
                                            ],
                                    "101" :  [
                                                "Abbigliamento e accessori", "Altre categorie", "Arte e antiquariato", "Auto, moto e altri veicoli", "Bellezza e salute", "Biglietti ed eventi", "Casa, arredamento e bricolage", "Collezionismo", "Commercio, ufficio e Industria", "Elettrodomestici", "Film e DVD", "Fotografia e video", "Francobolli", "Fumetti", "Giardino e arredamento esterni", "Giocattoli e modellismo", 
                                                "Hobby creativi", "Infanzia e premaman", "Informatica", "Libri e riviste", "Monete e banconote", "Musica, CD e vinili", "Nautica e imbarcazioni", "Orologi e gioielli", "Sport e viaggi", "Strumenti musicali", "Telefonia fissa e mobile", "TV, audio e video", "Veicoli: ricambi e accessori", "Videogiochi e console", "Vini, caffè e gastronomia"
                                            ],
                                    "186" :  [
                                                "Arte y antigüedades", "Bebés", "Belleza y salud", "Cámaras y fotografía", "Casa, jardín y bricolaje", "Cine, DVD y películas", "Coches, Motos y Otros Vehíc.", "Coleccionismo", "Consolas y videojuegos", "Deportes", "Electrodomésticos", "Entradas y eventos", "Equipamiento y maquinaria", "Imagen y sonido",
                                                "Informática y tablets", "Instrumentos musicales", "Juguetes", "Libros, revistas y cómics", "Monedas y billetes", "Motor: recambios y accesorios", "Móviles y telefonía", "Música, CDs y vinilos", "Otras categorías", "Relojes y joyas", "Ropa, calzado y complementos", "Sellos", "Viajes", "Vinos y gastronomía"
                                            ],
                                    "15"  :   [
                                                "Clothes, Shoes & Accessories", "Coins", "Collectables", "Jewellery & Watches", "Musical Instruments", "Vehicle Parts & Accessories", "Books, Magazines", "Business", "Cameras", "Cars, Bikes, Boats", "Food & Drinks", "Gift Cards & Vouchers", "Home Appliances", "Home Entertainment", "Industrial", "Lots More...", "Movies", 
                                                "Phones & Accessories", "Pottery, Glass", "Services", "Toys, Hobbies", "Unknown", "Tickets, Travel", "Antiques", "Art", "Baby", "Computers/Tablets & Networking", "Crafts", "Dolls & Bears", "Electronics", "Health & Beauty", "Home & Garden", "Music", "Pet Supplies", "Sporting Goods", "Stamps", "Video Games & Consoles"
                                            ],
                                    "0" :    [
                                                "Antiques", "Art", "Auto & Teile", "B&I", "Baby", "Beauty", "Books", "Buillon", "Business & Industrial", "Cameras and Photos", "Cell Phones & Accessories", "Clothing, Shoes & Accessories", "Coins & Paper Money", "Collectibles", "Computers/Tablets & Networking", "Consumer Electronics", "Crafts", "Dolls & Bears", "DVDs & Movies", 
                                                "eBay Motors", "Elec Certified Refurbished", "Electronics", "Entertainment Memorabilia", "Everything Else", "Fashion", "Food", "Gift Cards", "Gift Cards & Coupons", "Gold", "H&G + SG", "H&G Certified Refurbished", "Health", "Health & Beauty", "Heavy Equipment", "Home & Garden", "Jewelry", "Jewelry & Watches", "Music", 
                                                "Musical Instruments & Gear", "P&A", "Parts & Accessories", "Parts & Attachments", "Pet Supplies", "Pottery & Glass", "Sneakers", "Sport", "Sporting Certified Refurbished", "Sporting Good", "Sporting Goods", "Sports Mem, Cards & Fan Shop", "Stamps", "Toys & Hobbies", "Travel", "Video Games & Consoles", "Watches"
                                            ],
                                    "2" :    [
                                                "Antiques","Art","Auto &amp; Teile","B&amp;I","Baby","Beauty","Books","Buillon","Business &amp; Industrial","Cameras and Photos","Cell Phones &amp; Accessories","Clothing, Shoes &amp; Accessories","Coins &amp; Paper Money","Collectibles","Computers/Tablets &amp; Networking","Consumer Electronics","Crafts","Dolls &amp; Bears","DVDs &amp; Movies","eBay Motors","Elec Certified Refurbished","Electronics","Entertainment Memorabilia","Everything Else","Fashion","Food","Gift Cards","Gift Cards &amp; Coupons",
                                                "Gold","H&amp;G + SG","H&amp;G Certified Refurbished","Health","Health &amp; Beauty","Heavy Equipment","Home &amp; Garden","Jewelry","Jewelry &amp; Watches","Music","Musical Instruments &amp; Gear","P&amp;A","Parts &amp; Accessories","Parts &amp; Attachments","Pet Supplies","Pottery &amp; Glass","Sneakers","Sport","Sporting Certified Refurbished","Sporting Good","Sporting Goods","Sports Mem, Cards &amp; Fan Shop","Stamps","Toys &amp; Hobbies","Travel","Video Games &amp; Consoles","Watches"
                                            ]
                                }
    */
    @track maxDealInsertSize = 150;
    @track isShowMessage = false;

    @track mDEItemConditionVal = { 
                                    "Neu" : "New", 
                                    //"New other" : "New other", 
                                    //"New with defects" : "New with defects", 
                                    //"Certified - Refurbished" : "Certified - Refurbished", 
                                    //"Excellent - Refurbished" : "Excellent - Refurbished", 
                                    //"Very Good - Refurbished" : "Very Good - Refurbished", 
                                    //"Good - Refurbished" : "Good - Refurbished", 
                                    //"Seller refurbished" : "Seller refurbished", 
                                    //"Like new" : "Like new", 
                                    "Gebraucht" : "Used", 
                                    //"Very good" : "Very good", 
                                    //"Good" : "Good", 
                                    //"Acceptable" : "Acceptable", 
                                    //"For parts or not working" : "For parts or not working", 
                                    //"Wiederaufarbeite" : "Refurbished"
                                    "Überholte" : "Refurbished"
                                }
    @track selectedCategories = [];//Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category

    //Sambath Seng - 13/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
    @wire(getSelectedCategories)
    getSelectedCategories({error, data}) {
        if (data) {
            data.forEach(category =>{
                this.selectedCategories.push(category);
            });
        }
    }

    get onShowLoadingSpinner() {
        return this.showLoadingSpinner;
    }
    get acceptedFormats() {
        return ['.csv'];
    }
    get disableUploadFile(){
        return this.isUnableUpload || (this.isDEUser && this.siteselectedVal == "");
    }
    get disableNextBtn(){
        // console.log(">>>>>>>>> disableNextBtn::: ", this.isNoFile);
        return (this.isNoFile || this.isDisableNextBtn);
    }
    get disableSubmitBtn() {
        // console.log('this.isReachLimit: ',this.isReachLimit,' this.deals.length',this.deals.length );
        return (this.isReachLimit || this.deals.length == 0);
    }
    get isShowTable(){
        return this.data.length > 0;
    }
    get jsonData(){
        return this.data;
    }
    /* MN-05062024-US-0015298
    get isDEUser() {
        return (this.currUserLang == "DE - Seller Portal");
    }
    */
    get totalRecord() {
        return this.totalRec;
    }
    get allObjMessageInfos(){
        // console.log(">>>> display msg:", this.objMessageInfos);
        return this.objMessageInfos;
    }
    get showMessageResults() {
        //this.allMessageInfo[index]["cls_status"] = "cls_error";
        var messageErrors = [];
        var totalSuccess = 0;
        
        for(var i =0; i < this.allMessageInfo.length; i++){
            var obj = this.allMessageInfo[i];
            if(obj["cls_status"] == "cls_error") {
                messageErrors.push(obj["message"]);
            } else  totalSuccess++;
        }

        this.objMessageResult["isHasSuccess"] = (messageErrors.length == 0);
        this.objMessageResult["totalSuccess"] = totalSuccess;

        this.objMessageResult["isHasError"] = (messageErrors.length > 0);
        this.objMessageResult["lstError"] = messageErrors;
        return this.objMessageResult;
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
    connectedCallback() {
        var params = this.getQueryParameters();
        this.recordId = params["recordId"];
        this.startDate = params["startDate"];
        this.endDate = params["endDate"];
        this.country = params["country"];
        //console.log(">>>>>>>>> params:", params);
        this.doLoadCMT();
        // this.doLoadDealRetailCampaign(); //NEED TO DOUBLE CHECK //MN-21122021-US-0011048
        //console.log(">>>>>>>>> this.recordId", this.recordId);

        
    }

    
    //MN-21122021-US-0011048 - Fixed codes behavior by query existed deal with NULL DRC ID (this.recordId)
    doLoadCMT(){
        // console.log(">>>>resultddd recordId:", this.recordId);
        // console.log(">>>>LWCBulkUploadCSVError1:", this.label.LWCBulkUploadCSVError1);
        /*console.log(">>>>resultddd startDate:", this.startDate);
        console.log(">>>>resultddd endDate:", this.endDate);
        console.log(">>>>resultddd country:", this.country);*/
        this.existingItemIds = [];
        //this.recordId = 'a0u1F0000022jpnQAA';// for testing
        doLoadSetting({dealReatilCampaingId : this.recordId})
        .then(result => {
             //console.log(">>>> doLoadSetting resultdd:", result);
            this.objMessageInfos = [];
            this.isSomeError = false;
            var status = "error";
            var msg = "";
            var objMsgInfo;
            if(result["status"] == "success"){
                // this.availableDeal = result["availableDeal"]; //NOTE: Need to calculate else where //MN-21122021-US-0011048
                this.dd_DuplicateError = result["dd_DuplicateError"];
                this.userId = result["userId"];
                this.email = result["conEmail"];
                this.accountId = result["accountId"];
                this.contactId = result["contactId"];
                this.fullContactName = result["fullContactName"];
                this.totalDealOfDEToday = (result["totalDealOfDEToday"] != undefined ? result["totalDealOfDEToday"] : 0);
                
                this.availableDeal = result.availableDeal;
                /* //MN-21122021-US-0011048 - When page is onload, user not yet select any DRC yet so there is no use DRC/Deal infor that we can retrieve
                var lstDeal = result["lstDeal"];
                for(var i = 0; i < lstDeal.length; i++){
                    var deal = lstDeal[i];
                    this.existingItemIds.push(deal["EBH_eBayItemID__c"]);
                }
                */ 
                //console.log('result: ',result)
                
                // console.log('currUserLang: ',result["currUserLang"]);
                if(result["currUserLang"]) this.currUserLang = result["currUserLang"];
                if(result["isEU"]) this.isDEUser = result["isEU"]; //MN-05062024-US-0015298: use SP Main Domain instead of Profile Name
                //var testMsg = {className : "cls_message-info", mainMsg : "INFO", detailMsg : " ddddd teset "};
                //this.objMessageInfos.push(testMsg);

                //if(this.currUserLang == "DE - Seller Portal") { 
                if(this.isDEUser) { //MN-05062024-US-0015298: use SP Main Domain instead of Profile Name

                    //this.isDEUser = true; //MN-05062024-US-0015298

                    this.mSiteWithCategorys = result["fieldDependencies"];
                    var availableDealToday = this.maxDEDealLimitPerDay - this.totalDealOfDEToday;
                    // console.log('availableDealToday: ',availableDealToday)
                    if(availableDealToday <= 0) {
                        this.isReachLimit = true;
                        this.isUnableUpload = true;
                        this.isNoFile = true;
                        this.isDisableNextBtn = true;
                        msg = this.label.LWCBulkUploadCSVError2;
                        //this.objMessageInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                        objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                        this.objMessageInfos.push(objMsgInfo);
                    } else {

                        this.availableDeal = availableDealToday;
                        var infoMsg = this.label.LWCBulkUploadCSVError38;
                        infoMsg = infoMsg.replace(" X ", " "+ this.availableDeal + " ");
                        infoMsg = infoMsg.replace(" x ", " "+ this.availableDeal + " ");
                        objMsgInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : infoMsg};
                        this.objMessageInfos.push(objMsgInfo);
                        //console.log(">>>>>>> this.objMessageInfos:", this.objMessageInfos);
                    }

                } else if(this.availableDeal > 0){
                    // var drcRec = result["drcRec"];
                    // console.log('AMT reach EBH_OpenSeatsAvailable__c>>>', result["drcRec"]);
                    
                    this.isReachLimit = false;
                    status = "info";  
                    msg = this.label.LWCBulkUploadCSVError1.replace(" x "," "+ this.availableDeal +" "); //"You may upload up to another "+ this.availableDeal + (this.currUserLang == "DE - Seller Portal"? " Deals.":" Deals in this Deal Window.");
                    //this.objMessageInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : msg};
                    objMsgInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : msg};
                    this.objMessageInfos.push(objMsgInfo);
                } else {
                    ///msg = "You have reached the deal limit for this window.";
                    msg = this.label.LWCBulkUploadCSVError2;
                    //this.objMessageInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                    objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                    this.objMessageInfos.push(objMsgInfo);
                }

                this.doMapErrorMessages();
                ///Command cuz of EBAY-719
                /*if(this.currUserLang == "DE - Seller Portal") {
                    this.objMessageInfos = [];
                    this.availableDeal = 99999999; // make high value due to no limit if we don't chose DRC
                }*/
                //console.log("this.existingItemIds:::", this.existingItemIds);
                //console.log(">>>>>>>first load this.objMessageInfos:", this.objMessageInfos);
            } else {
                this.isReachLimit = true;
                msg = result["message"];
                //this.doShowTast(status.toUpperCase(), msg, status, "sticky");
                //this.objMessageInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                this.objMessageInfos.push(objMsgInfo);
            }
           
            this.doLoadDealRetailCampaign();
            
            //this.doShowTast(status.toUpperCase(), msg, status, "sticky");
            //console.log(">>> status:" + status.toUpperCase() + ">>> msg:" + msg +">>> status:" + status);
        })
        .catch(error => { 
            console.log(">>>>>first load ERROR:", error);
            //this.error = error;
            //console.log(">>>>errordddd ", error);
            //this.doShowTast('Error!', error.body.message, 'error');
        }); 
        
    }

    doLoadDealOverlapDateDRC(){
        
        getDealOverlapDateDRC({drcId : this.selectedVal, currUserLang : this.currUserLang})
        .then(result => {
            // console.log(">>>> doLoadDealOverlapDateDRC result:", result);
            this.existingDEDealItemIds = [];
            if(result["status"] == "success"){
                var lstDeal = result["lstDeal"];
                for(var i = 0; i < lstDeal.length; i++){
                    var deal = lstDeal[i];
                    this.existingDEDealItemIds.push(deal["EBH_eBayItemID__c"]);
                }

                //MN-21122021-US-0011048 - Moved from doLoadCMT()
                var lstExistedDeal = result["lstExistedDeal"];
                for(var i = 0; i < lstExistedDeal.length; i++){
                    var deal = lstExistedDeal[i];
                    this.existingItemIds.push(deal["EBH_eBayItemID__c"]);
                }
            }
            //console.log(">>>> doLoadDealOverlapDateDRC this.existingDEDealItemIds:", this.existingDEDealItemIds);
            this.showLoadingSpinner = false;
            //this.doShowTast(status.toUpperCase(), msg, status, "sticky");
            //console.log(">>> status:" + status.toUpperCase() + ">>> msg:" + msg +">>> status:" + status);
        })
        .catch(error => { 
            // console.log(">>>>>first load ERROR:", error);
            this.showLoadingSpinner = false;
            //this.error = error;
            //console.log(">>>>errordddd ", error);
            //this.doShowTast('Error!', error.body.message, 'error');
        }); 
    }

    handleSelectedChange(event){
        //let obj = {selectedVal : selectedVal, record : this.mRecords[selectedVal]};
        //console.log(">>>>>> updateCheckBox:", (this.maxDEDealLimitPerDay - this.totalDealOfDEToday));
        if((this.maxDEDealLimitPerDay - this.totalDealOfDEToday) <= 0) return;
        this.showLoadingSpinner = true;
        this.data = [];
        this.objMessageInfos = [];
        this.fileName = "";
        this.drcDE = event.detail["record"];
        // console.log('**** handleSelectedChange - drcDE detail', this.drcDE);
        this.selectedVal = event.detail["selectedVal"];
        this.isNoFile = true;
        this.isDisableNextBtn = true;
        this.fileName = "";
        this.deals = [];
        this.existingDEDealItemIds = [];
        // console.log(">>>>>>onChange this.selectedVal:", this.selectedVal);
        this.availableDeal = this.maxDEDealLimitPerDay - this.totalDealOfDEToday;
        // console.log('**** handleSelectedChange - availableDeal', this.availableDeal);
        ///Command cuz of EBAY-719
        var objMsgInfo = {};
        if( this.selectedVal == undefined || this.selectedVal == "") {
            this.isReachLimit = false;
            this.isUnableUpload = false;
            //this.availableDeal = this.maxDEDealLimitPerDay - this.totalDealOfDEToday;

            if(this.availableDeal <= 0) {
                this.isUnableUpload = true;
                //this.objMessageInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : this.label.LWCBulkUploadCSVError2};
                this.objMessageInfos.push(objMsgInfo);
            } else {
                var infoMsg = this.label.LWCBulkUploadCSVError38;
                infoMsg = infoMsg.replace(" X ", " "+ this.availableDeal + " ");
                infoMsg = infoMsg.replace(" x ", " "+ this.availableDeal + " ");
                objMsgInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : infoMsg};
                this.objMessageInfos.push(objMsgInfo);
            }
            this.showLoadingSpinner = false;
        }else if(this.drcDE["EBH_OpenSeatsAvailable__c"] != undefined && this.drcDE["EBH_OpenSeatsAvailable__c"] > 0){
            this.isReachLimit = false;
            this.isUnableUpload = false;
            //this.availableDeal = this.drcDE["EBH_OpenSeatsAvailable__c"];
            this.openSeatsAvailable = this.drcDE["EBH_OpenSeatsAvailable__c"];
            //getDealOverlapDateDRC
            if(this.availableDeal >= this.openSeatsAvailable){
                var msgInfo = this.label.LWCBulkUploadCSVError1.replace(" x "," "+ this.openSeatsAvailable +" "); //"You may upload up to another "+ this.availableDeal + (this.currUserLang == "DE - Seller Portal"? " Deals.":" Deals in this Deal Window.");
                this.availableDeal = this.openSeatsAvailable;
                objMsgInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : msgInfo};
                this.objMessageInfos.push(objMsgInfo);
            } else {
                /* MN-22112021-US-0010731
                var infoMsg = this.label.LWCBulkUploadCSVError38;
                infoMsg = infoMsg.replace(" X ", " "+ this.availableDeal + " ");
                infoMsg = infoMsg.replace(" x ", " "+ this.availableDeal + " ");
                objMsgInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : infoMsg};
                this.objMessageInfos.push(objMsgInfo);
                */
                
                //MN-22112021-US-0010731
                var msgInfo = this.label.LWCBulkUploadCSVError1.replace(" x "," "+ this.availableDeal +" "); 
                objMsgInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : msgInfo};
                this.objMessageInfos.push(objMsgInfo);
                
            }
            
            //this.objMessageInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : msg};
            //objMsgInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : msgInfo};
            //this.objMessageInfos.push(objMsgInfo);
            this.doLoadDealOverlapDateDRC();
        } else {
            //this.deals = [];
            this.isReachLimit = true;
            this.isUnableUpload = true;
            this.isNoFile = true;
            this.isDisableNextBtn = true;
            //this.doShowTast(status.toUpperCase(), msg, status, "sticky");
            //this.objMessageInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
            objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : this.label.LWCBulkUploadCSVError17};
            this.objMessageInfos.push(objMsgInfo);
            this.showLoadingSpinner = false;
        }

        //console.log(">>>>>>selected change this.objMessageInfos:", this.objMessageInfos);
        
    }

    handleSiteSelectedChange(event){
        //console.log(">>>>>> updateCheckBox:", event.detail["selectedVal"]);

        if((this.maxDEDealLimitPerDay - this.totalDealOfDEToday) <= 0) return;

        this.data = [];
        this.objMessageInfos = [];
        var availableDealToday = this.maxDEDealLimitPerDay - this.totalDealOfDEToday;
        this.availableDeal = availableDealToday;
        if(this.availableDeal <= 0) {
            this.isUnableUpload = true;
            //this.objMessageInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
            var objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : this.label.LWCBulkUploadCSVError2};
            this.objMessageInfos.push(objMsgInfo);
        } else {
            var infoMsg = this.label.LWCBulkUploadCSVError38;
            infoMsg = infoMsg.replace(" X ", " "+ this.availableDeal + " ");
            infoMsg = infoMsg.replace(" x ", " "+ this.availableDeal + " ");
            var objMsgInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : infoMsg};
            this.objMessageInfos.push(objMsgInfo);
        }

        this.siteselectedVal = event.detail["selectedVal"];
        //console.log('selected valuee>>>>>>>>',this.siteselectedVal, this.file);
        if(this.siteselectedVal !=="" && this.file.name!=""){
            this.isNoFile = false;
            this.isDisableNextBtn = false;
        }

    }

    doMapErrorMessages(){

        this.mapErrorMessages[this.dd_DuplicateError] = this.label.LWCBulkUploadCSVError16;//this.dd_DuplicateError_display;// SCH: EBAY-634
        //SCH: EBAY-413
        this.mapErrorMessages["EBH_ProductTitle__c-Required"] = this.label.LWCBulkUploadCSVError20; // Required Field - ProductTitle
        this.mapErrorMessages["EBH_ProductTitle__c-Incorrect"] = this.label.LWCBulkUploadCSVError21; // Product Title needs shouldn't be more than 150 characters
        this.mapErrorMessages["EBH_Dealdateearliestpossible__c-Required"] = this.label.LWCBulkUploadCSVError22; // Required Field - Available from Date
        this.mapErrorMessages["EBH_Dealdateearliestpossible__c-Incorrect"] = this.label.LWCBulkUploadCSVError23; // Available From Date cannot be in past
        this.mapErrorMessages["EBH_Quantity__c-Required"] = this.label.LWCBulkUploadCSVError25; // Required Field - Quantity
        this.mapErrorMessages["EBH_Quantity__c-Incorrect"] = this.label.LWCBulkUploadCSVError26; // Incorrect Format - Quantity
        this.mapErrorMessages["EBH_SellerPrice__c-Required"] = this.label.LWCBulkUploadCSVError27; // Required Field - Seller Price
        //this.mapErrorMessages["EBH_SellerPrice__c-Incorrect"] = this.label.LWCBulkUploadCSVError28; // Incorrect Format - Seller Price //Loumnag:2022-01-17:US-0010959
        this.mapErrorMessages["EBH_SellerPrice__c-Incorrect"] = this.label.LWC_Valid_Specail_Character;//Loumnag:2022-01-17:US-0010959
        this.mapErrorMessages["EBH_EAN__c-Incorrect"] = this.label.LWCBulkUploadCSVError29; // Incorrect EAN - Only numeric values are allowed and cannot be lesser than 5 digits"
        this.mapErrorMessages["EBH_EAN__c-Required"] = this.label.LWCBulkUploadCSVError40; //Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] Required EAN for some categories
        this.mapErrorMessages["EBH_Category__c-Incorrect"] = this.label.LWCBulkUploadCSVError24; // Incorrect => Category allowed are: List all the categories which are allowed for this particular Deal Site
        this.mapErrorMessages["EBH_DealFormat__c-Incorrect"] = this.label.LWCBulkUploadCSVError32; // Incorrect => Invalid value enterred for Deal Format, allowed values are: List the picklist values in the language"
        this.mapErrorMessages["EBH_eBayItemID__c-Required"] = this.label.LWCBulkUploadCSVError35; // Required Field - Item Id
        this.mapErrorMessages["EBH_eBayItemID__c-Incorrect"] = this.label.LWCBulkUploadCSVError36; // Incorrect => Invalid format - Item Id: Need to be 12 digits numeric value
        this.mapErrorMessages["Item_Condition__c-Incorrect"] = this.label.LWCBulkUploadCSVError33; // Incorrect => Invalid values: Item Condition - Allowed values are: New, Used or Refurbished"
        this.mapErrorMessages["EBH_AmazonLink__c-Incorrect"] = this.label.LWCBulkUploadCSVError30; // Incorrect => Invalid Format: Amazon URL, must start with http:// or https://
        this.mapErrorMessages["EBH_IdealoLink__c-Incorrect"] = this.label.LWCBulkUploadCSVError31; // Incorrect => Invalid Format: Idealo Link, must start with http:// or https://  
        
    }
 
    doDownloadCSVTemplate(){

        // Creating anchor element to download
        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        // downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(this.csvString);
        //this.currUserLang = 'Germany'; // add for testing
        
        
        //if(this.currUserLang == "DE - Seller Portal") downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(this.csvStringGerman); //MN-14122021-US-0010945
        //else downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(this.csvString); //MN-14122021-US-0010945
        
        //MN-05062024-US-0015298
        //if(this.currUserLang == "DE - Seller Portal") downloadElement.href = bulkUploadDealTemplateDE;  //MN-14122021-US-0010945- Download the DE Template via Static Resource
        if(this.isDEUser) downloadElement.href = bulkUploadDealTemplateDE; //MN-05062024-US-0015298: use SP Main Domain instead of Profile Name

        else downloadElement.href = bulkUploadDealTemplateNA //MN-14122021-US-0010945- Download the NA Template via Static Resource
        
        downloadElement.target = '_self';
        // CSV File Name
        //downloadElement.download = (this.currUserLang == "DE - Seller Portal"?"Vorlage zum Hochladen von Bulk-Deals.csv":"Bulk Deal Upload Template.csv"); //MN-05062024-US-0015298
        downloadElement.download = (this.isDEUser?"Vorlage zum Hochladen von Bulk-Deals.csv":"Bulk Deal Upload Template.csv"); //MN-05062024-US-0015298: use SP Main Domain instead of Profile Name
        
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click(); 

    }


    handleFilesChange(event) {
        this.isShowMessage = false;
        //this.objMessageInfo = {className : 'hide'}
        this.objMessageInfos = [];

        //console.log(">>> mSobjectFields: ", JSON.stringify(this.mSobjectFields));
        this.data = [];
        this.deals = [];
        //this.itemIds = [];
        //console.log('>>>>>>>> event.target.files:',event.target.files.length);
        if(event.target.files.length > 0) {
            //SCH: Ticket => EBAY-716
            /*if(this.siteselectedVal!=""){
                this.isNoFile = false;
            }*/

            //if(this.siteselectedVal =="" && this.currUserLang == "DE - Seller Portal"){ //MN-05062024-US-0015298
            if(this.siteselectedVal =="" && this.isDEUser){ //MN-05062024-US-0015298: use SP Main Domain instead of Profile Name
                this.isNoFile = true;
                this.isDisableNextBtn = true;
            } else {
                this.isNoFile = false;
                this.isDisableNextBtn = false;
            }
            this.file = event.target.files[0];
            this.fileName = event.target.files[0].name;
        }
    }

    handleClickUpload(){
        //this.objMessageInfo = {className : 'hide'}
        this.objMessageInfos = [];
        this.allMessageInfo = [];
        this.objMessageResult = {};
        this.showLoadingSpinner = true;
        this.isShowMessage = false;
        let self = this;
        //this.isFinish = false;
        //console.log('>>>>>>>> accountId:',this.accountId);
        //console.log('>>>>>>>> email:',this.email);
        var reader = new FileReader();
        reader.readAsText(this.file, "UTF-8");//UTF-8 not working with german char , Cp1252 not working with gdoc
        reader.onload = function(evt) {
            self.fileContent =  evt.target.result;
            //console.log(">>>>>>> self.fileContent:", self.fileContent);
            if(self.fileContent) self.csvReader();
        }
    }

    doLoadDealRetailCampaign(){
        //console.log('recordId: ',this.recordId)
        getDealRetailCampaign({recordId : this.recordId})
            .then(result => {
                console.log('result  doLoadDealRetailCampaign: ',result);
                if(result["status"] == "success"){
                    //console.log('here: ',result["dealRetailCampaign"])
                    this.dealRetailCampaign = result["dealRetailCampaign"];
                }
            })
    }

    //Sambath Seng - 17/12/2021 - US-001766 - fixing bulk upload
    validateHeader(csvHeader, csvTemplate){
        var error = false;
        var csvTemplateArray = csvTemplate.split(',');
        if(csvHeader.length == csvTemplateArray.length){
            for(var i = 0; i<csvTemplateArray.length; i++){
                if(!csvHeader[i].startsWith(csvTemplateArray[i].substring(0,3))){
                    error = true;
                }
            }
        } else {
            error = true;
        }
        return error ? false : true;
    }

    csvReader(){
        try{
            /*if(this.currUserLang == "DE - Seller Portal"){
                if(this.selectedVal != ""){
                    if(this.drcDE["EBH_OpenSeatsAvailable__c"] != undefined && this.drcDE["EBH_OpenSeatsAvailable__c"] > 0){
                        this.availableDeal = this.drcDE["EBH_OpenSeatsAvailable__c"];
                    } else {
                        this.isReachLimit = true;
                    }
                } else {
                    this.availableDeal = 99999999;
                }
            }*/
            this.isDisableNextBtn = true;

            // console.log('@@@@ siteselectedVal',this.siteselectedVal)
            if(this.siteselectedVal == ""){
                // console.log('@@@ inside')
                this.isUnableSiteUpload = true;
            }
            // console.log(">>>>>>>>>>>> this.availableDeal:", this.availableDeal);
            this.isShowMessage = false;
            this.isSomeError = false;
            this.allMessageInfo = [];
            this.mRowIndex = {};
            //var objIndexRow = {};
            var duplicateEbayIds = [];
            var duplicateRows = [];
            //var duplicateRows = [];
            var duplicatExistingeEbayIds = [];
            //var duplicateExistingRows = [];
            var mDuplicateRow = {};

            var ebayIds = [];
            this.totalRec = 0;
            this.isSomeFail = false;
            var allTextLines = this.CSVToArray();
            var dataIncomplete = false;
            //var rowsIncomplete = 0;
            var csvHeader = allTextLines[0];
            // changes for EBAY - 457
            let EBH_DealFormat = {
                "WOW! Angebot (Basket)": "Core",
                "Deal": "Deal",
                "WOW! Angebot der Woche": "Featured",
                "WOW! Angebot des Tages": "Primary",
            };
                     
            // if(allTextLines[0] == this.csvHeader1 || allTextLines[0] == this.csvHeader2 || csvHeader == this.csvHeaderGerman1 || csvHeader == this.csvHeaderGerman2){   
            //Sambath Seng - 17/12/2021 - US-001766 - fixing bulk upload
            if(this.validateHeader(csvHeader,this.csvHeader1) || this.validateHeader(csvHeader,this.csvHeader2) || this.validateHeader(csvHeader,this.csvHeaderGerman1) || this.validateHeader(csvHeader,this.csvHeaderGerman2)){            
                var tempData = [];
                var tempDeals = [];
                //console.log(">>>> this.currUserLang dd:", this.currUserLang);

                //var cols = (this.currUserLang == "DE - Seller Portal"? this.defaulColsGerman : this.defaulCols ); //MN-05062024-US-0015298
                var cols = (this.isDEUser? this.defaulColsGerman : this.defaulCols ); //MN-05062024-US-0015298: use SP Main Domain instead of Profile Name

                //var colsLength = (this.currUserLang == 'Germany'? cols.length : cols.length - 1);
                //console.log(">>>> allTextLines[0]:", allTextLines[0]);
                //console.log(">>>> cols.length:", cols);

                //console.log(">>>> allTextLines length:", (allTextLines[0]).length);
                //console.log(">>>> cols.length:", cols.length -1);
                if((allTextLines[0]).length != cols.length - 2){
                    ///var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : 'Invalid CSV file'};
                    var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.label.LWCBulkUploadCSVError3};
                    this.objMessageInfos.push(objMsgInfo);
                    this.showLoadingSpinner = false;
                    return;
                }

                //console.log(">>>> cols:", cols);
                //console.log(">>>>>>>>> dealRetailCampaign:",this.dealRetailCampaign);
                if(this.availableDeal > 0) this.isReachLimit = false;

                //this.totalRec = allTextLines.length - 1;
                var index = 0;
                //var today = new Date();
                //var tomorrow = new Date(today);
                //tomorrow.setDate(tomorrow.getDate() + 1);
                //console.log(">>>>>>> today:", today);
                //console.log(">>>> tomorrow:", tomorrow);
                var tempMIndex = {};
                var mIdRowNum = {};
                var rowNumber = 0;
                var rowT = 0;
                var mAllRowNumber = {};
                for(var i = 1; i < allTextLines.length; i++) {
                    //console.log('alltext: ',allTextLines[i]) 
                    rowNumber++;
                    rowT++;
                    var msg = "";
                    var msgNumeric = "";
                    var msgErrorPicklistVal = "";
                    var msgEbayItem = "";
                    var isInvalidId = false;
                    var rowIncomplete = false;
                    var isValueInvalidFormat = false;
                    var isInvalidPickListVal = false;
                    var allCols = allTextLines[i];
                    //console.log('allCols: ',allCols.length);
                    //console.log('cols: ',cols.length);
                    if(allCols.length != cols.length-2) continue;

                    let deal = { "sobjectType": "EBH_Deal__c" };
                    var row = {};
                    row["id"] = i;
                    var isRowEmpty = true;
                    var eanValue = "";//Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
                    for(var x= 0; x < allCols.length; x++) {
                        var colName = cols[x+2].fieldName;
                        var fieldType = cols[x+2]["type"];
                        if(colName == "status" || colName == "Item_ID_Product_Title__c" || colName == "row_number") continue;
                        var val = allCols[x]? allCols[x] : "";
                        if(val != undefined && val != "" && val != " ") {
                            isRowEmpty = false;
                        }
                        row[colName] = val;
                        //if( colName == "Item_ID_Product_Title__c" ) continue;
                        deal[colName] = val;

                        /*if(val != "" && colName == "EBH_Dealdateearliestpossible__c") {
                            //var dt = new Date(val);
                            //deal[colName] = dt;
                            //console.log(">>>>> dtddd:", dt);
                            deal[colName] = this.convertDateToString(val);
                        }*/

                        /*if(val != "" && colName == "Item_Condition__c" && this.mDEItemConditionVal[val] != undefined){
                            deal[colName] = this.mDEItemConditionVal[val];
                        }*/
                        //SCH: EBAY-720: Remove seller email field from Bulk upload
                        //if(colName == "EBH_SellerEmail__c") deal["EBH_SellerEmail__c"] = (val != ""? val : this.email);
                        /*
                            var dt = new Date(val);
                            deal[fieldName] = dt;
                        */
                        
                        if(this.isDEUser && colName != "EBH_eBayItemID__c" && row[colName] == "" && this.requiredDealFields.includes(colName)){
                            //msg += (msg==""? "" :", ") +cols[x+2].label;
                            //console.log(">>colName xx:", colName);
                            //console.log(">>colName msg:", this.mapErrorMessages[colName+"-Required"]);
                            msgNumeric += (msgNumeric==""? "" :", ") + this.mapErrorMessages[colName+"-Required"];
                            rowIncomplete = true;
                            continue;
                        }

                        if( this.isDEUser && this.validateFormatFields.includes(colName)){
                            //["EBH_eBayItemID__c", "EBH_DealPrice__c", "List_Price__c", "EBH_Quantity__c", "EBH_SellerPrice__c", "EBH_Dealdateearliestpossible__c", "EBH_ProductTitle__c", "EBH_EAN__c", "EBH_Category__c", "EBH_DealFormat__c", "Item_Condition__c", "EBH_AmazonLink__c", "EBH_IdealoLink__c"]; 
                            //console.log(">>colName xx:", colName);
                            //console.log(">>>>> val xx:", val);
                            var tempMsg = "";
                            var isValNumeric = this.isNumeric(val);
                            if(colName == "EBH_eBayItemID__c" && val != ""){
                                if(!isValNumeric || val.length != 12) {
                                    tempMsg = this.mapErrorMessages["EBH_eBayItemID__c-Incorrect"];
                                    isValueInvalidFormat = true;
                                }
                            }
                            if (colName == "EBH_Quantity__c") {
                                //console.log(">>>>> this.isInt(val) xx:", this.isInt(val));
                                if(!isValNumeric || !this.isInt(val) || val.length > 18){
                                    tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                                    isValueInvalidFormat = true;
                                }
                            } 
                            if (colName == "EBH_SellerPrice__c") {
                                //val = val.replace(",",".");
                                // console.log(">>>>> isValNumeric:", isValNumeric);
                                // console.log(">>>>> (this.isInt(val):", this.isInt(val));
                                // console.log(">>>>> (this.isFloat(val):", this.isFloat(val));
                                //isFloat
                                //if(!isValNumeric || (this.isInt(val) && val.length > 16) || (this.isFloat(val) && !this.checkPriceFormat(val,16,2))) {
                                if(!this.checkPriceFormat(val,16,2)) {
                                    tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                                    isValueInvalidFormat = true;
                                } else {
                                    // console.log('La parseFloat(val)::',val);
                                    //val = val.replace(".","").replace(",",".");
                                    //val = val.replace(".","");
                                    deal[colName] = val;
                                }
                            } 
                            if (colName == "EBH_Dealdateearliestpossible__c") {
                                //console.log(">>>>> val.includes:", val.includes("/"));
                                if(val.includes("/") || val.includes(".") || val.includes("-")) {
                                    var dateParts = ( val.includes("/")? val.split("/") : (val.includes(".")? val.split(".") : val.split("-")));
                                    // console.log(">>>>> dateParts:", dateParts);
                                    // console.log(">>>>> month:"+dateParts[1]+"::", dateParts[1] > 12);
                                    // console.log(">>>>> year:"+dateParts[2]+"::", (dateParts[2]).length != 4);
                                    if(dateParts.length == 3 && dateParts[0] > 0 && dateParts[1] > 0 && dateParts[1] <= 12 && (dateParts[2]).length == 4){
                                        var dt1 = new Date(+dateParts[2], dateParts[1] - 1, +dateParts[0]);
                                        
                                        var d = new Date();
                                        d.setHours(0,0,0,0);
                                        // console.log(">>>>> dt1:", dt1);
                                        // console.log(">>>>>   d:", d);
                                        if(dt1 == undefined) {
                                            tempMsg = this.label.LWCBulkUploadCSVError37;
                                            isValueInvalidFormat = true;
                                        } else if(dt1 < d) {
                                            tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                                            isValueInvalidFormat = true;
                                        }
                                    } else {
                                        tempMsg = this.label.LWCBulkUploadCSVError37;
                                        isValueInvalidFormat = true;
                                    }
                                } else {
                                    tempMsg = this.label.LWCBulkUploadCSVError37;
                                    isValueInvalidFormat = true;
                                }

                                if(!isValueInvalidFormat){
                                    deal[colName] = this.convertDateToString(val);
                                }
                            } 
                            if (colName == "EBH_ProductTitle__c" && val.length > 150) {
                                tempMsg = this.mapErrorMessages[colName + "-Incorrect"];
                                isValueInvalidFormat = true;
                            } 
                            //console.log(">>>>>EBH_EAN__c val: ", val);
                            //console.log(">>>>>EBH_EAN__c lengthdd: ", val.length < 5);

                            /****Loumang:03-11-2021:US-0010729 - [SP - EU Deals] [Bug] EAN accepting text****/
                            //if (colName == "EBH_EAN__c" && val != "" && val.length < 5) {
                            
                            //Start - Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
                            if (colName == "EBH_EAN__c"){
                                if (val != "" ) {
                                    if(!isValNumeric || val.length < 5) {
                                        tempMsg = this.mapErrorMessages[colName + "-Incorrect"];
                                        isValueInvalidFormat = true;
                                    }
                                    eanValue = val;
                                } else {
                                    eanValue = "";
                                }
                            }
                            //End - Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
                            if (colName == "EBH_Category__c" && this.siteselectedVal != "") {
                                var allCatg = (this.mSiteWithCategorys[this.siteselectedVal] != undefined ? this.mSiteWithCategorys[this.siteselectedVal] : []);
                                //console.log(">>>>>>> allCatg:", allCatg);
                                if(!allCatg.includes(val)) {
                                    tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"]+" '"+allCatg.join("' , '")+"'" : "");
                                    isValueInvalidFormat = true;
                                }
                                //Start - Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
                                if(eanValue == "" && this.selectedCategories.includes(val)){
                                    tempMsg = this.mapErrorMessages["EBH_EAN__c-Required"];
                                    rowIncomplete = true;
                                }
                                //End - Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
                            } 
                            if (colName == "EBH_DealFormat__c" && val != "") {
                                //console.log(">>>>>>> EBH_DealFormat__c:", val);
                                if(Object.keys(EBH_DealFormat).includes(deal['EBH_DealFormat__c'])){
                                    deal['EBH_DealFormat__c'] = EBH_DealFormat[deal['EBH_DealFormat__c']];
                                }else {
                                    tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                                    isValueInvalidFormat = true;
                                }
                            } 
                            if (colName == "Item_Condition__c") {
                                if(val == "" || this.mDEItemConditionVal[val] == undefined) {
                                    tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                                    isValueInvalidFormat = true;
                                } else {
                                    deal[colName] = this.mDEItemConditionVal[val];
                                }
                            } 
                            if (colName == "EBH_AmazonLink__c" && val != "") {
                                if(!val.startsWith("http://") && !val.startsWith("https://")){
                                    tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                                    isValueInvalidFormat = true;
                                }
                            } 
                            if (colName == "EBH_IdealoLink__c" && val != "") {
                                if(!val.startsWith("http://") && !val.startsWith("https://")){
                                    tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                                    isValueInvalidFormat = true;
                                }
                            }
                            // console.log(">>>>>>>>> tempMsg:"+colName+":", tempMsg);
                            if(tempMsg != "") msgNumeric += (msgNumeric==""? "" :", ") + tempMsg;

                        }

                        if(!this.isDEUser ){
                            if(this.isDEUser && row[colName] == "" && this.requiredDealFields.includes(colName)){
                                msg += (msg==""? "" :", ") +cols[x+2].label;
                                rowIncomplete = true;
                                continue;
                            }
                        
                            if(colName == "EBH_eBayItemID__c") {
                                if(this.isNumeric(val)) {
                                    if(val.length != 12){
                                        ///msgEbayItem = "Listing ID must be numeric and 12 characters in length. ";
                                        msgEbayItem = this.label.LWCBulkUploadCSVError4;
                                        isInvalidId = true;
                                        continue;
                                    }
                                }
                            }

                            if(val != "" && (colName == "EBH_eBayItemID__c" || fieldType == "number" || fieldType == "currency")) {
                                if(!this.isNumeric(val)) {
                                    //msgNumeric += (msgNumeric==""? "" :", ") +cols[x+2].label;

                                    msgNumeric += (msgNumeric==""? "" :", ") +cols[x+2].label;

                                    isValueInvalidFormat = true;
                                    continue;
                                }
                            }
                        }
                    }
                    var strRow = (allTextLines[i]).join();

                    if (allTextLines[i][0] != "" && (duplicateRows.includes(strRow) || isRowEmpty == true)){
                        if(!duplicateRows.includes(strRow)) duplicateRows.push(strRow);
                        rowT--;
                        rowNumber--;
                        continue;
                    }
                    row["row_number"] = rowNumber;
                    if(mAllRowNumber[allTextLines[i][0]] == undefined) {
                        mAllRowNumber[allTextLines[i][0]] = [rowNumber];
                    } else {
                        var allRowNum = mAllRowNumber[allTextLines[i][0]];
                        allRowNum.push(rowNumber);
                        mAllRowNumber[allTextLines[i][0]] = allRowNum;
                    }
                    //tempData.push(row);
                    //if(objIndexRow[row["EBH_eBayItemID__c"]] == undefined) objIndexRow[row["EBH_eBayItemID__c"]] = i;
                    var objMsg = {"row_number" : i};
                    this.allMessageInfo.push(objMsg);
                    // console.log(">>>>>>> isValueInvalidFormat:"+rowNumber+":", isValueInvalidFormat);
                    if(rowIncomplete || isValueInvalidFormat || isInvalidId || isInvalidPickListVal){
                        /*
                        //rowsIncomplete++;
                        var errorMsg = (isInvalidId == true ? msgEbayItem : "");
                        ///errorMsg += (msg != ""? "Required field [" + msg + "] missing value. " : "");
                        // Required field [ebay item Id,...] missing value.
                        if(msg != ""){
                            errorMsg = this.label.LWCBulkUploadCSVError5.replace("<fields> ", " ["+ msg + "] ")+" ";
                        }
                        //[List Price,...] Incorrect Format.
                        ///errorMsg += (msgNumeric != ""?  " [" + msgNumeric + "] Incorrect Format. " : "");
                        if(msgNumeric != "") {
                            errorMsg = this.label.LWCBulkUploadCSVError6.replace("<fields> ", " ["+ msgNumeric + "] ")+" ";
                        }
                        if(msgErrorPicklistVal != "") {
                            errorMsg = this.label.LWCBulkUploadCSVError19.replace("<fields> ", " ["+ msgErrorPicklistVal + "] ")+" ";
                        }*/
                        var errorMsg = "";
                        if(this.isDEUser) {
                            errorMsg = msgNumeric;
                        } else {
                            errorMsg = (isInvalidId == true ? msgEbayItem : "");
                            if(msg != ""){
                                errorMsg = this.label.LWCBulkUploadCSVError5.replace("<fields> ", " ["+ msg + "] ")+" ";
                            }
                            if(msgNumeric != "") {
                                errorMsg = this.label.LWCBulkUploadCSVError6.replace("<fields> ", " ["+ msgNumeric + "] ")+" ";
                            }
                            if(msgErrorPicklistVal != "") {
                                errorMsg = this.label.LWCBulkUploadCSVError19.replace("<fields> ", " ["+ msgErrorPicklistVal + "] ")+" ";
                            }
                        }
                        row["isNotOverrid"] = true;
                        row["status"] = errorMsg;
                        row["cls_status"] = "cls_error";
                        this.isSomeError = true;
                        objMsg["cls_status"] = "cls_error";
                        //objMsg["message"] = "- Row number: "+ rowNumber +".Required field [" + msg + "] missing value";
                        objMsg["message"] = "- " + this.label.RowNumber  + " " + rowNumber +". "+errorMsg;
                        tempData.push(row);
                        ///this.allMessageInfo.push(objMsg);
                        continue;
                    }

                    /*if(isValueInvalidFormat){
                        row["status"] = "[" + msg + "] Incorrect Format";
                        row["cls_status"] = "cls_error";
                        this.isSomeError = true;
                        objMsg["cls_status"] = "cls_error";
                        objMsg["message"] = "- Row number: "+ rowNumber +". Error: [" + msg + "] Incorrect Format.";
                        tempData.push(row);
                        continue;
                    }*/
                    console.log('**** this.selectedVal :: ', this.selectedVal);
                    console.log(">>>>>>>. this.existingDEDealItemIds:", this.existingDEDealItemIds);
                    console.log(">>>>>>>. this.existingItemIds:", this.existingItemIds);
                    //console.log(">>>>>>>. this.duplicate:",this.existingDEDealItemIds.includes(allTextLines[i][0]));
                    if (allTextLines[i][0] != "" && this.isDEUser && this.existingDEDealItemIds.includes(allTextLines[i][0])) {
                        if(mDuplicateRow[allTextLines[i][0]] != undefined ){
                            msg = this.label.LWCBulkUploadCSVError8.replace(" x ",mDuplicateRow[allTextLines[i][0]] +","+ i+" ");
                        } else msg = this.label.LWCBulkUploadCSVError7;
                        
                        row["isNotOverrid"] = true;
                        row["status"] = msg;
                        row["cls_status"] = "cls_error";
                        this.isSomeError = true;

                        objMsg["cls_status"] = "cls_error";
                        objMsg["message"] = "- " + this.label.RowNumber  + " "+rowNumber+". "+ msg;
                        tempData.push(row);
                        ///this.allMessageInfo.push(objMsg);
                        continue;
                        
                    //}else if(this.existingItemIds.includes(allTextLines[i][0])){
                    }else if( (!this.isDEUser || (this.isDEUser && this.selectedVal == "") )&& this.existingItemIds.includes(allTextLines[i][0])){
                        if(!duplicatExistingeEbayIds.includes(allTextLines[i][0])) duplicatExistingeEbayIds.push(allTextLines[i][0]);
                        //msg = "Required field " + cols[x].label + "missing value";
                        //msg = "duplicate with the existing deal("+allTextLines[i][0]+")";
                        //msg = "Failed";
                        //msg = "You have already submitted this item.";
                        msg = this.label.LWCBulkUploadCSVError7;
                        row["isNotOverrid"] = true;
                        row["status"] = msg;
                        row["cls_status"] = "cls_error";
                        this.isSomeError = true;

                        objMsg["cls_status"] = "cls_error";
                        //objMsg["message"] = "- Row number: "+i+". Error: This deal is duplicated by deals: "+ allTextLines[i][0] +", please remove these and try again";
                        objMsg["message"] = "- " + this.label.RowNumber  + " "+ rowNumber+". "+msg;
                        tempData.push(row);
                        ///this.allMessageInfo.push(objMsg);
                        continue;
                    /*} else if (duplicateRows.includes(strRow)){
                        if(!duplicateRows.includes(strRow)) duplicateRows.push(strRow);
                        rowT--;
                        rowNumber--;
                        continue;*/
                    } else if(allTextLines[i][0] != "" &&  ebayIds.includes(allTextLines[i][0])) {
                        if(!duplicateEbayIds.includes(allTextLines[i][0])) duplicateEbayIds.push(allTextLines[i][0]);
                        //duplicateRows.push("row "+i);
                        mIdRowNum[allTextLines[i][0]] = (mIdRowNum[allTextLines[i][0]] == undefined?rowNumber : mIdRowNum[allTextLines[i][0]]+","+rowNumber);
                        //msg = (mDuplicateRow[allTextLines[i][0]] != undefined ? "duplicate with row:"+ mDuplicateRow[allTextLines[i][0]] : "duplicate with the existing deal");
                        //Conflicting data in rows: 4, 5 please delete and resubmit
                        ///msg = (mDuplicateRow[allTextLines[i][0]] != undefined ? "Conflicting data in rows: "+ mDuplicateRow[allTextLines[i][0]] +","+ i +" please delete and resubmit" : "duplicate with the existing deal");
                        if(mDuplicateRow[allTextLines[i][0]] != undefined ){
                            msg = this.label.LWCBulkUploadCSVError8.replace(" x ",mDuplicateRow[allTextLines[i][0]] +","+ i+" ");
                        } else msg = "duplicate with the existing deal";
                        row["status"] = msg;
                        row["cls_status"] = "cls_error";
                        this.isSomeError = true;

                        objMsg["cls_status"] = "cls_error";
                        objMsg["message"] = "- " + this.label.RowNumber  + " "+rowNumber+". "+ msg;
                        tempData.push(row);
                        ///this.allMessageInfo.push(objMsg);
                        continue;
                    } else {
                        mDuplicateRow[allTextLines[i][0]] = rowNumber;
                        ebayIds.push(allTextLines[i][0]);
                        duplicateRows.push(strRow);
                        //console.log(">>>>>>>>> duplicateRows ddddd:", duplicateRows);
                        // console.log(">>>>>>>>> this.label.LWCBulkUploadCSVError10:", this.label.LWCBulkUploadCSVError10);
                        msg = this.label.LWCBulkUploadCSVError10; //"Ready to Upload";
                        row["status"] = msg;
                        row["cls_status"] = "cls_success";

                        objMsg["cls_status"] = "cls_success";
                        objMsg["message"] = msg;
                        //this.mRowIndex[index] = i;
                        tempMIndex[index] = rowT-1;
                        
                        index++;
                    }

                    deal["EBH_BusinessName__c"] = this.accountId;
                    deal["Seller_Contact__c"] = this.contactId;
                    deal["Seller_Name__c"] = this.fullContactName;

                    //SCH: EBAY-720: Remove seller email field from Bulk upload. We also need to stamp the User.Contact.Email into the EBH_SellerEmail__c field on all bulk created deals.
                    deal["EBH_SellerEmail__c"] = this.email;
                    ///if(this.currUserLang != "DE - Seller Portal") deal["EBH_SellerEmail__c"] = this.email;

                    //TH:09/12/2021:US-0010968 - BUG-[SP-NA Deals] Unsub Deal showing wrong status in HIVE and SEP Portal
                    //deal["EBH_Status__c"] = this.currUserLang == "DE - Seller Portal" ? "New" : "Processing"; //MN-05062024-US-0015298
                    deal["EBH_Status__c"] = this.isDEUser ? "New" : "Processing"; //MN-05062024-US-0015298: use SP Main Domain instead of Profile Name
                    
                    //if(this.currUserLang == "DE - Seller Portal") deal["EBH_DealPrice__c"] = deal["EBH_SellerPrice__c"]; //MN-05062024-US-0015298
                    if(this.isDEUser) deal["EBH_DealPrice__c"] = deal["EBH_SellerPrice__c"]; //MN-05062024-US-0015298: use SP Main Domain instead of Profile Name
                    
                    //if(this.dealRetailCampaign != undefined && this.currUserLang != "DE - Seller Portal"){ //MN-05062024-US-0015298
                    if(this.dealRetailCampaign != undefined && !this.isDEUser){ //MN-05062024-US-0015298: use SP Main Domain instead of Profile Name
                        // console.log('@@@inside if condtionnn no dee')
                        if(this.dealRetailCampaign["EBH_Date__c"] != undefined) deal["EBH_DealStartDate__c"] = this.dealRetailCampaign.EBH_Date__c;
                        
                        if(this.dealRetailCampaign["Start_Time__c"] != undefined) deal["EBH_DealStartTime__c"] = this.dealRetailCampaign.Start_Time__c;
                        if(this.dealRetailCampaign["EPH_EndDate__c"] != undefined) deal["EBH_DealEndDate__c"] = this.dealRetailCampaign.EPH_EndDate__c;
                        
                        if(this.dealRetailCampaign["End_Time__c"] != undefined) deal["EBH_DealEndTime__c"] = this.dealRetailCampaign.End_Time__c;
                        if(this.dealRetailCampaign["startDate"] != undefined) deal["EBH_Dealdateearliestpossible__c"] = this.startDate;
                        
                        if(this.recordId != undefined) deal["EBH_DealRetailCampaign__c"] = this.recordId;
                        if(this.dealRetailCampaign["EBH_Country__c"] != undefined) deal["EBH_DealSiteId__c"] = this.dealRetailCampaign.EBH_Country__c;
                    } else {
                        if(this.selectedVal != ""){
                            deal["EBH_DealRetailCampaign__c"] = this.selectedVal;
                        }
                        if(this.siteselectedVal != ""){
                            deal["EBH_DealSiteId__c"] = this.siteselectedVal;
                        }
                        // SHC: move to check on top
                        // changes for EBAY - 457
                        /*if(Object.keys(EBH_DealFormat).includes(deal['EBH_DealFormat__c'])){
                            console.log('@@@@@ EBH_DealFormat',EBH_DealFormat[deal['EBH_DealFormat__c']]);
                            deal['EBH_DealFormat__c'] = EBH_DealFormat[deal['EBH_DealFormat__c']];
                        }else {
                            msg = this.label.LWCBulkUploadCSVError18;
                            row["status"] = msg;
                            row["cls_status"] = "cls_error";
                            this.isSomeError = true;
                            objMsg["cls_status"] = "cls_error";
                            objMsg["message"] = "- Row number: "+ rowNumber+". Error: "+msg;
                        }*/
                        // console.log('after sett>>',deal);
                            
                        /*deal["EBH_DealStartDate__c"] = today;
                        deal["EBH_DealEndDate__c"] = tomorrow;
                        deal["EBH_Dealdateearliestpossible__c"] = today;
                        deal["EBH_DealPrice__c"] = 123;
                        deal["EBH_MaximumPurchases__c"] = 123;*/
                    }
                    ///this.allMessageInfo.push(objMsg);
                    // console.log('>>> after sett deal:',deal);
                    tempData.push(row);
                    tempDeals.push(deal);
                    // console.log('>>> tempDeals:',tempDeals);
                    
                    //if(tempDeals.length > this.availableDeal || (this.currUserLang == "DE - Seller Portal" && this.selectedVal != "" && tempDeals.length > this.openSeatsAvailable)){
                    if(tempDeals.length > this.availableDeal){
                        this.isReachLimit = true;
                        //this.doShowTast('Error!', 'You cannot upload the Deal records more than '+ this.availableDeal+".", 'error', "sticky");

                        ///'You may only upload '+ this.availableDeal + ' more deals'+(this.currUserLang == 'DE - Seller Portal'?'.' : ' in this deal window'
                        var errMsg = this.label.LWCBulkUploadCSVError11;
                        errMsg = errMsg.replace(" x ", " "+ this.availableDeal + " ")
                        var objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : errMsg};
                        this.objMessageInfos.push(objMsgInfo);
                        tempDeals = [];
                        tempData = [];
                        break;
                    } 
                }
                
                if(duplicatExistingeEbayIds.length > 0) {
                    //var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : 'This deal is duplicated by deals: '+ duplicatExistingeEbayIds.join(', ') +', please remove these and try again'};
                    
                    //this.objMessageInfos.push(objMsgInfo);
                }
                
                if(duplicateEbayIds.length > 0) {
                    //var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR : ', detailMsg : "There are duplicate deals: "+duplicateEbayIds.join(", ")+" in your upload, please remove these and try again "};
                    //this.objMessageInfos.push(objMsgInfo);
                }

                for(var i = 0; i < tempData.length; i++){
                    //console.log(">>>>>>>>> tempData:", tempData[i]);
                    var ebayItem = tempData[i]["EBH_eBayItemID__c"];
                    //row["isNotOverrid"] = true;
                    if(tempData[i]["isNotOverrid"] != undefined && tempData[i]["isNotOverrid"] == true) continue;
                    if(ebayItem != "" && mAllRowNumber[ebayItem] != undefined) {
                        var allRowIds = mAllRowNumber[ebayItem];
                        if(allRowIds.length > 1) {
                            tempData[i]["cls_status"] = "cls_error";
                            var errMsg = this.label.LWCBulkUploadCSVError8.replace(" x ", " "+allRowIds.join()+" ")
                            tempData[i]["status"] = errMsg;//"Conflicting data in row "+ allRowIds.join() +". please delete and resubmit";
                            var objMsg1 = {"row_number": i+1};
                            objMsg1["cls_status"] = "cls_error";
                            objMsg1["message"] = "- " + this.label.RowNumber  + " "+(i+1)+". "+ errMsg;//"Conflicting data in row "+ allRowIds.join() +". please delete and resubmit";
                        
                            this.allMessageInfo[i] = objMsg1;
                        }
                    }
                }
                //var statusIndex = cols.length -1;
                //cols[1]["initialWidth"] = (this.currUserLang == "DE - Seller Portal" ? (this.isSomeError ? 360 : 140) : (this.isSomeError ? 330 : 115)); //MN-05062024-US-0015298
                cols[1]["initialWidth"] = (this.isDEUser ? (this.isSomeError ? 360 : 140) : (this.isSomeError ? 330 : 115)); //MN-05062024-US-0015298: use SP Main Domain instead of Profile Name
                
                //initialWidth: 100,
                //this.existingItemIds.includes(allTextLines[i][0])
                //console.log(">>>>> this.allMessageInfo xxx:", this.allMessageInfo);
                //console.log(">>>>> tempMIndex[i]:", tempMIndex);
                //console.log(">>>>> temIdx:", tempMIndex[i]);

                var tDeals = [];
                var idx = 0;
                for(var i = 0; i < tempDeals.length; i++){
                    var ebayId = tempDeals[i]["EBH_eBayItemID__c"];
                    /*console.log(">>>>> ebayId:", ebayId);
                    console.log(">>>>> temIdx:", tempMIndex[i]);
                    console.log(">>>>> this.existingItemIds.includes(ebayId):", !this.existingItemIds.includes(ebayId));
                    console.log(">>>>> this.existingItemIds.includes(ebayId):", !duplicateEbayIds.includes(ebayId));*/
                    if(!this.existingItemIds.includes(ebayId) && !duplicateEbayIds.includes(ebayId)){
                        tDeals.push(tempDeals[i]);
                        //console.log(">>>>> ddddd:", tempMIndex[i]);
                        this.mRowIndex[idx] = tempMIndex[i];
                        idx++;
                        
                    }
                    
                } 
                this.showLoadingSpinner = false;
                //console.log(">>>>>>>> tDealsxxxx:",tDeals);
                this.data = tempData;
                this.totalRec = tempData.length;
                this.columns = cols;
                ///There are x deals in your file ready for upload!
                var dealForUpload = this.label.LWCBulkUploadCSVError12;
                dealForUpload = dealForUpload.replace(" x ", " "+ tDeals.length + " ");
                if(tDeals.length > 0) {
                    //this.objMessageInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : 'There are duplicate deals['+ duplicateEbayIds.join('],[') +'] in your upload, please remove these and try again'};
                    var objMsgInfo = {className : 'cls_message-info cls_message-success', mainMsg : '', detailMsg : dealForUpload}; //' vailable deals in your file for upload!'};
                    this.objMessageInfos.push(objMsgInfo);
                    this.showLoadingSpinner = false;
                    //return;
                } else {
                    this.showLoadingSpinner = false;
                    var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : '', detailMsg : dealForUpload}; //' vailable deals in your file for upload!'};
                    this.objMessageInfos.push(objMsgInfo);
                    return;
                } 
                // console.log(">>>>>>>> tDealsxxxxxxx:",tDeals); 
                this.deals = tDeals;
                
                //console.log(">>>>>>>> this.deals:",this.deals);
                //console.log(">>>>>>>> this.data:",this.data);
            } else {
                //console.log("Invalid CSV format");
                //this.doShowTast('Error!', 'Invalid CSV format', 'error', 'dismissible');
                //this.objMessageInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : 'Invalid CSV format'};
                this.showLoadingSpinner = false;
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.label.LWCBulkUploadCSVError13};// 'Invalid CSV format'};
                
                this.objMessageInfos.push(objMsgInfo);
            }
            
            this.showLoadingSpinner = false;
        } catch( err){
            this.showLoadingSpinner = false;
            //this.doShowTast('Error!', err.message, 'error', 'sticky');
            //this.objMessageInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : err.message};
            var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : err.message};
            this.objMessageInfos.push(objMsgInfo);
        }
        
    }

    convertDateToString(val1){
        //var dt1 = new Date(val1);
        //var dateParts = val1.split("/");
        var dateParts = ( val1.includes("/")? val1.split("/") : (val1.includes(".")? val1.split(".") : val1.split("-")));
        //console.log(">>>>> dateParts:", dateParts);
        // month is 0-based, that's why we need dataParts[1] - 1
        var dt1 = new Date(+dateParts[2], dateParts[1] - 1, +dateParts[0]);

        //console.log(">>>>> dt1:", dt1);
        const date1 = dt1.getDate();
        const month1 = dt1.getMonth()+1;
        const year1 = dt1.getFullYear();
        //console.log(">>>>> date1:", date1);
        //console.log(">>>>> month1:", month1);
        //console.log(">>>>> year1:", year1);
        return year1+"-"+ ( month1 < 10? "0"+month1 : month1) +"-"+ (date1 < 10 ? "0"+date1 : date1);
    }

    CSVToArray() {
        //this.sizeOf(this.fileContent);
        //console.log(">>>>>>> xxxx:", this.formatByteSize());\
        //self.CSVToArray(content, separator);
        //console.log(">>>>>>> CSVToArray:");
        var objPattern = new RegExp(("(\\" + this.selectedSeperator + "|\\r?\\n|\\r|^)" +"(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" + "([^\"\\" + this.selectedSeperator + "\\r\\n]*))"), "gi");
        //console.log(">>>>>>> objPattern:", objPattern);
        var arrData = [[]];
        var arrMatches = null;
        //console.log(">>>>>>> allTextLines:", allTextLines);
        while (arrMatches = objPattern.exec(this.fileContent)) {
            //console.log(">>>>>>> arrMatches:", arrMatches);
            var strMatchedDelimiter = arrMatches[1];
            //console.log(">>>>>>> strMatchedDelimiter:", strMatchedDelimiter);
            if (strMatchedDelimiter.length && (strMatchedDelimiter != this.selectedSeperator)) {
                arrData.push([]);
            }
            if (arrMatches[2]) {
                var strMatchedValue = arrMatches[2].replace(new RegExp("\"\"", "g"), "\"");
            } else {
                var strMatchedValue = arrMatches[3];
            } 
            arrData[arrData.length - 1].push(strMatchedValue);
        }
        return (arrData);
    }

    handleClickSubmit() {
        this.dealsComplete = [];
        this.dealSaveResult = [];
        this.objMessageResult = {};
        this.objMessageInfos = []; 
        this.isSomeFail = false;
        this.message = "";
        this.onProccessUpload(this.deals);
    }
    onProccessUpload(lstDeal){
        this.showLoadingSpinner = true;
        // chunk list of deal to small size for pass into apex
        var arrAllDeals = this.chunkArray(lstDeal, this.numberOfDealPerPk);
        //console.log(">>>>>>>. arrAllDeals:", arrAllDeals);
        this.onSubmitMultipleDeals(arrAllDeals, 0, arrAllDeals.length);
    }
    onSubmitMultipleDeals(arrAllDeals, index, total){ 
        if( index < total && arrAllDeals[index]){ 
            //console.log(">>>>>>>. index:", index);
            // console.log(">>>>>>>. arrAllDeals[index]:", arrAllDeals[index]);
            //deal["EBH_BusinessName__c"] = this.accountId;
            doSubmitMultipleDeals({lstDeals: arrAllDeals[index], accountId: this.accountId})
            .then(result => {
                index++;
                // console.log(">>>>>>>. result ddd:", result);                
                //console.log(">>>>>>>. result srList:", JSON.parse(srList));
                if(result['status'] == 'success'){
                    var srList = result["srList"];
                    //this.doShowTast('Success!', result['message'], 'success');
                    this.dealSaveResult = this.dealSaveResult.concat(JSON.parse(srList));
                    if(result["lstDeals"]){
                        this.dealsComplete = this.dealsComplete.concat(result["lstDeals"]);
                    }
                } 
                else {
                    this.isSomeFail = true;
                    this.message = result['message'];
                    //console.log(">>>>>>>. lstDealsddd:", lstDeals);
                    //if(this.message) FIELD_CUSTOM_VALIDATION_EXCEPTION, There are non-cancelled deals with same Listing ID
                    if((this.message).includes("FIELD_CUSTOM_VALIDATION_EXCEPTION, There are non-cancelled deals with same Listing ID") ){
                        this.message = this.label.LWCBulkUploadCSVError14; //"One of the items included in this upload has already been submitted for this deal period. ";
                    }//
                    //One of the items included in this upload has already been submitted for this deal period.
                    if((this.message).includes("FIELD_CUSTOM_VALIDATION_EXCEPTION, Listing ID must be numeric and 12 characters in length") ){
                        this.message = "The 'eBay Item Id' must be numeric and contain 12 digits in length";
                    }
                    if((this.message).includes("Cannot deserialize instance of")){
                        this.message =result['message'];
                    }
                }
                

                //console.log(">>>>>>>. this.isSomeFail:", this.isSomeFail);
                if(this.isSomeFail) {
                    //this.onClearFailDeals();

                } else if (index < total) {

                    this.onSubmitMultipleDeals(arrAllDeals, index, total);

                } else if(!this.isSomeFail && index == total){
                    //this.doShowTast('Success!', result['message'], 'success', 'dismissible');
                    //this.objMessageInfo = {className : 'cls_message-info cls_message-success', mainMsg : 'SUCCESS', detailMsg : result['message']};
                    ///this.redirectToFutureDeals();
                    this.onUpdateStatus();
                }
            })
            .catch(error => {
                this.isSomeFail = true;
                // console.log('msgErr error:',error);
                this.message = (error["body"] != undefined? error.body.message : error);
                // console.log(">>>> error done:",this.message);
                //"You have entered your data incorretcly, please try again."
                this.message = (this.message=="Unable to read SObject's field value[s]"? this.label.LWCBulkUploadCSVError15 : this.message);
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.message};
                this.objMessageInfos.push(objMsgInfo);
                this.dealsComplete = [];
                this.isSomeFail = false;
                this.message = "";
                this.showLoadingSpinner = false;
                //console.log('msgErr: ',error.body.message)

                //this.message = error.body.message;
                //if( msgErr.includes("Unable to read SObject's field")) this.message = msgErr;
                
                //this.message = (this.message.includes("Unable to read SObject's field")? this.message : "Server Error");
                //this.onClearFailDeals();
                
            });
        }
    }

    onUpdateStatus() {

        this.isShowMessage = true;
        var allSaveResult = this.dealSaveResult;

        for(var i = 0; i < allSaveResult.length; i++){
            //console.log(">>>>>>>. this.dealSaveResult:", allSaveResult[i]);
            //console.log(">>>>>>>. this.mRowIndex:"+i+":", this.mRowIndex[i]);
            var index = this.mRowIndex[i];
            //objMsg["cls_status"] = "cls_error";
            //objMsg["message"] = "- Row number: "+i+".This deal is duplicated by deals: "+ allTextLines[i][0] +" in your upload, please remove these and try again";
            if(allSaveResult[i]["success"] == false) {
                this.isSomeError = true;
                //console.log(">>>>>>>. this.allMessageInfo[index]:", this.allMessageInfo[index]);
                this.allMessageInfo[index]["cls_status"] = "cls_error";
                var msg = "";
                var errors = allSaveResult[i]["errors"];
                for(var x = 0; x < errors.length; x++){
                    msg += (msg==""? "":", ") + errors[x]["message"]; //errors[x]["statusCode"]+ ":" +
                }

                if(this.dd_DuplicateError != undefined && this.dd_DuplicateError != "" && this.mapErrorMessages[this.dd_DuplicateError] != undefined && msg.startsWith(this.dd_DuplicateError)){
                    msg = this.mapErrorMessages[this.dd_DuplicateError];
                }

                this.allMessageInfo[index]["message"] = "- " + this.label.RowNumber  + " "+(index+1)+". "+msg+"\n";
            }           
        } 
        if(this.isSomeError == false) {
            this.redirectToFutureDeals();
        }
        this.data = [];
        this.objMessageInfos = []; 
        this.doLoadCMT();
        this.showLoadingSpinner = false;
    }
    
    /*onClearFailDeals(){
        //console.log(">>>>>>>Clear. this.dealsComplete:", this.dealsComplete);
        this.objMessageInfos = [];
        if(this.dealsComplete.length > 0){
            doRemoveHalfCompleteDeals({lstDeals: this.dealsComplete})
            .then(result => {
                console.log(">>>>>>>. Remove:", result);
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.message};
                this.objMessageInfos.push(objMsgInfo);
                this.dealsComplete = [];
                this.isSomeFail = false;
                this.message = "";
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                console.log(">>>> error onClearFailDeals:", error);
                this.showLoadingSpinner = false;
            });
        } else {
            //this.doShowTast('Error!', this.message, 'error', 'sticky');
            var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.message};
            this.objMessageInfos.push(objMsgInfo);
            this.dealsComplete = [];
            this.isSomeFail = false;
            this.message = "";
            this.showLoadingSpinner = false;
            console.log(">>>> error done:",this.message);
        }
        
    }*/
    
    chunkArray(myArray, chunk_size){
        var results = [];
    
        while (myArray.length) {
            results.push(myArray.splice(0, chunk_size));
        }
        
        return results;
    }

    isNumeric(val) {
        return /^-?[\d.]+(?:e-?\d+)?$/.test(val);
    }
    
    isFloat(val) {
        return (!isNaN(val) && val.toString().indexOf('.') != -1);
        /*var floatRegex = /^-?\d+(?:[.,]\d*?)?$/;
        if (!floatRegex.test(val))
            return false;
    
        val = parseFloat(val);
        if (isNaN(val))
            return false;
        return true;*/
    }
    
    isInt(val) {
        var intRegex = /^-?\d+$/;
        if (!intRegex.test(val))
            return false;
    
        var intVal = parseInt(val, 10);
        return parseFloat(val) == intVal && !isNaN(intVal);
    }

    checkPriceFormat(val, index0, index1) {
        if(this.isDEUser) val = val.replace(".","/").replace(",",".");//LA-13-12-2021:US-0010738 - [SP - EU Deals] [Bug] Align Seller Price accepted values on Bulk upload with Single deal form
        var arrVal = val.split(".");
        // console.log(">>>>>>> val:", arrVal);
        // console.log(">>>>>>> arrVal:", (arrVal[0]).length);
        // console.log(">>>>>>> arrVal:", ((arrVal[0]).length <= index0) );
        if(arrVal.length == 2 && (this.isNumeric(arrVal[0]) && arrVal[0]).length <= index0 && this.isNumeric(arrVal[1]) && (arrVal[1]).length <= index1){
            return true;
        } else if ( arrVal.length < 2 && this.isNumeric(arrVal[0]) && (arrVal[0]).length <= index0){
            return true;
        } else {
            return false;
        }
        //alert(arrVal[0] + " : "+ arrVal[1]);
        
        //return ((arrVal[0]).length <= index0 && (arrVal[1]).length == index1);
    }

    redirectToFutureDeals() {
        // redirect to create deal page
        /* MN-07012022-US-0010947 - Redirect to Deal Page
        if(this.currUserLang == "DE - Seller Portal") {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'home'
                },
            });
        }else if(this.redirectToUrl != ""){
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: this.redirectToUrl + (this.tabName !=""? "?"+ this.tabName : "") //'/ebh-deal/EBH_Deal__c/Default' + (this.tabName !=""? "?"+ this.tabName : "")
                }
            });
        }
        */
        //MN-07012022-US-0010947 - Redirect to Deal Page
        
        if(this.redirectToUrl != ""){
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: this.redirectToUrl + (this.tabName !=""? "?"+ this.tabName : "") //'/ebh-deal/EBH_Deal__c/Default' + (this.tabName !=""? "?"+ this.tabName : "")
                }
            });
        }else {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'home'
                },
            });
        }
        
    }
    doShowTast(title, message, variant, mode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode : mode
            }),

        );
    }
    cancelhandler() {
        console.log('La direct Deal');
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: '/ebh-deal/EBH_Deal__c/Default'
            }
        });
        
    }
}