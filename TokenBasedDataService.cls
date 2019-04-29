
@RestResource(urlMapping='/tokenbasedData/*')
global without sharing class TokenBasedDataService{

    global static String token='';
    global static DateTime expiredTimeValue=null;
    global static Boolean checkExpireFlag =false;
    trainrider__ExternalUserId__c etu=new trainrider__ExternalUserId__c();
    @HttpGet
    global static MessageWrapper generateTokenforUser(){

        MessageWrapper messagewrapper=null;
        String username=RestContext.request.params.get('username');
        String password=RestContext.request.params.get('password');

        List<trainrider__ExternalUserId__c> updateLst=new List<trainrider__ExternalUserId__c>();
        trainrider__ExternalUserId__c etu=new trainrider__ExternalUserId__c();
        List<trainrider__ExternalUserId__c> exuserLst=[select id, trainrider__UserName__c,trainrider__Password__c,trainrider__TokenKey__c,trainrider__ExpiredDate_Time__c from trainrider__ExternalUserId__c where trainrider__UserName__c=:username and trainrider__Password__c=:password];
        if(exuserLst.size()>0){
            etu=exuserLst[0];
        }

        try {
            if(!String.isBlank(username) && !String.isBlank(password)){
                if(etu.trainrider__UserName__c==username && etu.trainrider__Password__c==password){
                    token=generateRandomToken();
                    expiredTimeValue = DateTime.now().addSeconds(100);
                    messagewrapper = new MessageWrapper('success','Token generated successfully.',token,200);

                    etu.trainrider__TokenKey__c = token;
                    etu.trainrider__ExpiredDate_Time__c=expiredTimeValue;
                    updateLst.add(etu);
                }else{
                    messagewrapper = new MessageWrapper('error','Token not found','null',500);
                }

            }else{
                messagewrapper = new MessageWrapper('error','username or password not found in request','null',409);
            }

            if(updateLst.size()>0){
                update updateLst;
            }

        } catch(Exception e) {
            messagewrapper = new MessageWrapper('error',e.getMessage(),'null',500);            
        }

        return messagewrapper;
    }

    @HttpPost
    global static LeadGenerateData fetchLeadData(){
        LeadGenerateData leadWrapper =null;
        String reqToken=RestContext.request.params.get('tokenid');
        String username=RestContext.request.params.get('username');
        trainrider__ExternalUserId__c  trexid=new trainrider__ExternalUserId__c();
        List<trainrider__ExternalUserId__c> exuserLst=[select id,trainrider__ExpiredDate_Time__c,trainrider__TokenKey__c,trainrider__UserName__c from trainrider__ExternalUserId__c where trainrider__UserName__c=:username or trainrider__TokenKey__c=:reqToken];

        if(exuserLst.size()>0){
            trexid = exuserLst[0];
        }

        checkExpireFlag =  checkTokenExpire(trexid.trainrider__ExpiredDate_Time__c,trexid.trainrider__TokenKey__c);

        if(checkExpireFlag==false && reqToken==trexid.trainrider__TokenKey__c){
            List<Lead> lst= QueryLeadData();
            leadWrapper = new LeadGenerateData('Data Received successfully',lst,200);
        }else{
            leadWrapper = new LeadGenerateData('Token expired',null,401);
        }

        return leadWrapper;
    }
    public static String generateRandomToken(){
		//String charString = '!@#$%^&*()nopqrstuvwABCDPQRSTUVWXYZ0123456789abcdefghijkEFGHIJKLMNOlmxyz';
		String charString = 'nopqrstuvwABCDPQRSTUVWXYZ0123456789abcdefghijkEFGHIJKLMNOlmxyz';
		
		String randomNew = '';
		while (randomNew .length() < 18){
			Integer changeInt = Math.mod(Math.abs(Crypto.getRandomInteger()), charString.length());
			randomNew += charString.substring(changeInt , changeInt +1);
		}
		return randomNew ;
	}

    public static Boolean checkTokenExpire(Datetime expiredateTime,String username){

		DateTime currentdatTime =datetime.now();

		System.debug('currentdatTime--'+currentdatTime+' expiredateTime--'+expiredateTime+' user'+username);
		
		List<trainrider__ExternalUserId__c> updteUser=new List<trainrider__ExternalUserId__c>();
		List<trainrider__ExternalUserId__c> expireUser=[select Id,trainrider__UserName__c,trainrider__TokenKey__c from trainrider__ExternalUserId__c where trainrider__UserName__c=:username];
		trainrider__ExternalUserId__c trexu=new trainrider__ExternalUserId__c();
		if(expireUser.size()>0){
			trexu=expireUser[0];
        }
		
        if(currentdatTime > expiredateTime){
			trexu.trainrider__TokenKey__c='';
			updteUser.add(trexu);
			update updteUser;
			System.debug('true');
			return true;
		}else{

			System.debug('false');
			return false;
		}
		
	}

    public static List<Lead> QueryLeadData(){
        List<Lead> lst=[select Id,Name from Lead limit 5];
        return lst;
    }
    
    global class LeadGenerateData{

        public String message;
        public List<lead> ldlst;
        public integer responsecode;

        global LeadGenerateData(String message, List<Lead> lst, Integer responsecode){
            this.message=message;
            this.ldlst=lst;
            this.responsecode=responsecode;
        }
    }
    
    global class MessageWrapper{

        public String result;
        public String message;
        public String token;
        public integer responsecode;

        global MessageWrapper(String result,String message,String token,integer responsecode){

            this.result=result;
            this.message=message;
            this.token=token;
            this.responsecode=responsecode;
        }
    }
}
