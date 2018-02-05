public with sharing class ContractCalculatorBuilder {

    private Lending_Contract__c mContract;
    private fsCore.CalculatorObject mCalcObject;
    
    public ContractCalculatorBuilder(Lending_Contract__c pContract){
        mContract = pContract;
        mCalcObject = new fsCore.CalculatorObject();
    }

    public fsCore.CalculatorObject getCalculatorObject(){
        return mCalcObject;
    }
    
    public ContractCalculatorBuilder setCalculator(String pCalculationTask){
        fsCore__Calculator__c calc = new fsCore__Calculator__c();
        calc.fsCore__Task__c = pCalculationTask;
        calc.fsCore__Annual_Percent_Rate__c = (mContract.Current_Annual_Percent_Rate__c == null ? 0.00 : mContract.Current_Annual_Percent_Rate__c);
        calc.fsCore__Balloon_Amount__c = (mContract.Current_Balloon_Amount__c == null ? 0.00 : mContract.Current_Balloon_Amount__c);
        calc.fsCore__Balloon_Method__c = mContract.Balloon_Method__c;
        calc.fsCore__Billing_Method__c = mContract.Billing_Method__c;
        calc.fsCore__Day_Calendar_Method_360__c = mContract.Day_Calendar_Method_360__c;
        calc.fsCore__Final_Payment_Amount__c = (mContract.Final_Payment_Amount__c == null ? 0.00 : mContract.Final_Payment_Amount__c);
        calc.fsCore__Finance_Fee__c = (mContract.Finance_Fee__c == null ? 0.00 : mContract.Finance_Fee__c);
        calc.fsCore__Financed_Amount__c = (mContract.Financed_Amount__c == null ? 0.00 : mContract.Financed_Amount__c);
        calc.fsCore__First_Period_Day_Count_Method__c = mContract.First_Period_Day_Count_Method__c;
        calc.fsCore__First_Period_Days__c = (mContract.First_Period_Days__c == null ? 0 : mContract.First_Period_Days__c);
        calc.fsCore__First_Period_Interest_Amount__c = 0.00;
        calc.fsCore__Fixed_Principal_Amount__c = (mContract.Fixed_Principal_Amount__c == null ? 0.00 : mContract.Fixed_Principal_Amount__c);
        calc.fsCore__Interest_Calculation_Balance_Method__c = mContract.Interest_Calculation_Balance_Method__c;
        calc.fsCore__Interest_Day_Count_Method__c = mContract.Interest_Accrual_Base_Method__c;
        calc.fsCore__Interest_Only_Cycles__c = (mContract.Interest_Only_Term__c == null ? 0 : mContract.Interest_Only_Term__c);
        calc.fsCore__Start_Date__c = mContract.Contract_Date__c;
        calc.fsCore__Interest_Start_Date__c = (mContract.Interest_Accrual_Start_Date__c == null ? mContract.Contract_Date__c : mContract.Interest_Accrual_Start_Date__c);
        calc.fsCore__Interest_Compound_Frequency__c = mContract.Interest_Compound_Frequency__c;
        calc.fsCore__First_Compound_Date__c = mContract.First_Interest_Compounding_Date__c;
        calc.fsCore__Is_Due_Day_End_Of_Month__c = (mContract.Payment_Start_Date__c != null ? fscore.DateUtilGlobal.isLastDayOfMonth(mContract.Payment_Start_Date__c) : false);
        calc.fsCore__Is_Even_Payment_Multiple_Rates__c = mContract.Is_Even_Payment_Multiple_Rates__c;
        calc.fsCore__Is_Final_Payment_Different__c = mContract.Is_Final_Payment_Different__c;
        calc.fsCore__Loan_Amount__c = (mContract.Loan_Amount__c == null ? 0.00 : mContract.Loan_Amount__c);
        calc.fsCore__Maturity_Date__c = mContract.Current_Maturity_Date__c;
        calc.fsCore__Payment_Amount__c = (mContract.Current_Payment_Amount__c == null ? 0.00 : mContract.Current_Payment_Amount__c);
        calc.fsCore__Payment_Due_Day__c = mContract.Current_Payment_Due_Day__c;
        calc.fsCore__Payment_Frequency__c = mContract.Current_Payment_Frequency__c;
        calc.fsCore__Payment_Start_Date__c = mContract.Next_Payment_Due_Date__c;
        //calc.fsCore__Periodic_Fee__c = 0.00;
        calc.fsCore__Prepaid_Fee__c = (mContract.Prepaid_Fee__c == null ? 0.00 : mContract.Prepaid_Fee__c);
        calc.fsCore__Principal_Balance__c = 0.00;
        calc.fsCore__Product_Family__c = mContract.Product_Family__c;
        calc.fsCore__Rate__c = (mContract.Current_Rate__c == null ? 0.00 : mContract.Current_Rate__c);
        calc.fsCore__Supplementary_Interest_Amount__c = 0.00;
        calc.fsCore__Term__c = (mContract.Current_Term__c == null ? 0 : mContract.Current_Term__c);
        //calc.fsCore__Total_Finance_Charge__c = (mContract.Total_Financial_Charge__c == null ? 0.00 : mContract.Total_Financial_Charge__c);
        //calc.fsCore__Total_Interest_Amount__c = (mContract.Total_Interest_Amount__c == null ? 0.00 : mContract.Total_Interest_Amount__c);
        //calc.fsCore__Total_Of_Payments__c = (mContract.Total_Of_Payments__c == null ? 0.00 : mContract.Total_Of_Payments__c);
        
        mCalcObject.setCalculatorMain(calc);

        String adjustmentMethod = mContract.Holiday_Adjustment_Daily_Cycle__c;
        adjustmentMethod = String.IsBlank(adjustmentMethod) ? fsCore.Constants.HOLIDAY_ADJUSTMENT_NO_CHANGE : adjustmentMethod;
        
        if(mCalcObject.getCalculatorMain().fsCore__Payment_Frequency__c == fsCore.Constants.CYCLE_DAILY) { 
            mCalcObject.setHolidayAdjustmentMethod(adjustmentMethod);
        }

        return this;
    }
    
    public ContractCalculatorBuilder setBusinessHour(BusinessHours pBizHrs){
        this.mCalcObject.setBusinessHours(pBizHrs);
        return this;
    }
    
    public ContractCalculatorBuilder setHolidays(List<Holiday> pBizHolidayList){
        this.mCalcObject.setBizHolidayList(pBizHolidayList);
        return this;
    }

    public ContractCalculatorBuilder setInterestStartDate(Date pStartDate){
        this.getCalculatorObject().getCalculatorMain().fsCore__Start_Date__c = pStartDate;
        this.getCalculatorObject().getCalculatorMain().fsCore__Interest_Start_Date__c = pStartDate;
        return this;
    }
    
    public ContractCalculatorBuilder setTerm(Integer pTerm){
        this.getCalculatorObject().getCalculatorMain().fsCore__Term__c = pTerm;
        return this;
    }    
    
    public ContractCalculatorBuilder setRate(Decimal pRate){
        this.getCalculatorObject().getCalculatorMain().fsCore__Rate__c = pRate;
        return this;
    }    
    
    public ContractCalculatorBuilder setPaymentAmount(Decimal pPaymentAmount){
        this.getCalculatorObject().getCalculatorMain().fsCore__Payment_Amount__c = pPaymentAmount;
        return this;
    }    

    public ContractCalculatorBuilder setPaymentStartDate(Date pPaymentStartDate){
        system.debug(logginglevel.error,'this.getCalculatorObject -->'+this.getCalculatorObject());
        system.debug(logginglevel.error,'this.getCalculatorObject getCalculatorMain() -->'+this.getCalculatorObject().getCalculatorMain());
        this.getCalculatorObject().getCalculatorMain().fsCore__Payment_Start_Date__c = pPaymentStartDate;
        this.getCalculatorObject().getCalculatorMain().fsCore__Payment_Due_Day__c = pPaymentStartDate.day();
        return this;
    }   
    
    public ContractCalculatorBuilder setFrequency(String pPaymentFrequency){
        this.getCalculatorObject().getCalculatorMain().fsCore__Payment_Frequency__c = pPaymentFrequency;
        return this;
    }    

    public ContractCalculatorBuilder setFinancedAmount(Decimal pFinancedAmount){
        this.getCalculatorObject().getCalculatorMain().fsCore__Financed_Amount__c = pFinancedAmount;
        return this;
    }   
    
    public ContractCalculatorBuilder setSupplementaryInterest(Decimal pInterestAmount){
        this.getCalculatorObject().getCalculatorMain().fsCore__Supplementary_Interest_Amount__c = pInterestAmount;
        return this;
    }
    
    public ContractCalculatorBuilder setBalloonMethod(String pBalloonMethod){
        this.getCalculatorObject().getCalculatorMain().fsCore__Balloon_Method__c  = pBalloonMethod;
        return this;
    }
    
    public ContractCalculatorBuilder setBalloonAmount(Decimal pBalloonAmount){
        this.getCalculatorObject().getCalculatorMain().fsCore__Balloon_Amount__c = pBalloonAmount;
        return this;
    }             
    
    public ContractCalculatorBuilder setPredefinedPayments(List<Contract_Repayment_Schedule__c> pPredefinedPmtList){
        List<fsCore__Calculator_Repayment_Schedule__c> calcPredefinedPmtList = new List<fsCore__Calculator_Repayment_Schedule__c>();
        
        for (Contract_Repayment_Schedule__c predefinedPmt : pPredefinedPmtList){
            fsCore__Calculator_Repayment_Schedule__c calcPredefinedPmt = new fsCore__Calculator_Repayment_Schedule__c();

            calcPredefinedPmt.fsCore__Number_Of_Payments__c = predefinedPmt.Number_Of_Payments__c;
            calcPredefinedPmt.fsCore__Payment_Amount__c = predefinedPmt.Payment_Amount__c;
            calcPredefinedPmt.fsCore__Start_Term__c = predefinedPmt.Start_Term__c;
            calcPredefinedPmt.fsCore__Is_Predefined_Payment__c = predefinedPmt.Is_Predefined_Payment__c;
            
            calcPredefinedPmtList.add(calcPredefinedPmt);
        }
        
        mCalcObject.setPredefinedPayments(calcPredefinedPmtList);
        return this;
    }

    public ContractCalculatorBuilder setPaymentPreferences(List<Contract_Payment_Preference__c> pPaymentPrefList){
        List<fsCore__Calculator_Payment_Preference__c> calcPaymentPrefList = new List<fsCore__Calculator_Payment_Preference__c>();

        for (Contract_Payment_Preference__c paymentPref : pPaymentPrefList){
            fsCore__Calculator_Payment_Preference__c calcPaymentPref = new fsCore__Calculator_Payment_Preference__c();

            calcPaymentPref.fsCore__Change_Sequence__c = paymentPref.Change_Sequence__c;
            calcPaymentPref.fsCore__Change_Method__c = paymentPref.Change_Method__c;
            calcPaymentPref.fsCore__Change_Value__c = paymentPref.Change_Value__c;
            calcPaymentPref.fsCore__Change_Start_Term__c = paymentPref.Change_Start_Term__c;
            calcPaymentPref.fsCore__Is_Repetitive__c = paymentPref.Is_Repetitive__c;
            calcPaymentPref.fsCore__Repeat_Number_Of_Times__c = paymentPref.Repeat_Number_Of_Times__c;
            calcPaymentPref.fsCore__Repeat_Terms__c = paymentPref.Repeat_Terms__c;
            
            calcPaymentPrefList.add(calcPaymentPref);
        }
        
        mCalcObject.setPaymentPreferences(calcPaymentPrefList);
        return this;
    }

    public ContractCalculatorBuilder setHolidayPreferences(List<Contract_Holiday_Preference__c> pHolidayPrefList){
        List<fsCore__Calculator_Payment_Holiday_Preference__c> calcHolidayPrefList = new List<fsCore__Calculator_Payment_Holiday_Preference__c>();
        
        for (Contract_Holiday_Preference__c holidayPref : pHolidayPrefList){
            fsCore__Calculator_Payment_Holiday_Preference__c calcHolidayPref = new fsCore__Calculator_Payment_Holiday_Preference__c();

            calcHolidayPref.fsCore__Payment_Holiday_Unit__c = holidayPref.Payment_Holiday_Unit__c;
            calcHolidayPref.fsCore__Payment_Holiday_Month__c = holidayPref.Payment_Holiday_Month__c;
            calcHolidayPref.fsCore__Start_Date__c = holidayPref.Start_Date__c;
            calcHolidayPref.fsCore__End_Date__c = holidayPref.End_Date__c;
            calcHolidayPref.fsCore__Is_Repetitive__c = holidayPref.Is_Repetitive__c;
            
            calcHolidayPrefList.add(calcHolidayPref);
        }
        
        mCalcObject.setPaymentHolidays(calcHolidayPrefList);
        return this;
    }

    public ContractCalculatorBuilder setRatePreferences(List<Contract_Rate_Preference__c> pRatePrefList){
        List<fsCore__Calculator_Rate_Preference__c> calcRatePrefList = new List<fsCore__Calculator_Rate_Preference__c>();

        for (Contract_Rate_Preference__c ratePref : pRatePrefList){
            fsCore__Calculator_Rate_Preference__c calcRatePref = new fsCore__Calculator_Rate_Preference__c();

            calcRatePref.fsCore__Start_Date__c = ratePref.Start_Date__c;
            calcRatePref.fsCore__Rate__c = ratePref.Rate__c; 
            
            calcRatePrefList.add(calcRatePref);
        }
        
        mCalcObject.setRatePreferences(calcRatePrefList);
        return this;
    }

    public ContractCalculatorBuilder setRepaymentSchedule(List<Contract_Repayment_Schedule__c> pRepayScheduleList){
        List<fsCore__Calculator_Repayment_Schedule__c> calcRepaySchtList = new List<fsCore__Calculator_Repayment_Schedule__c>();
        
        for (Contract_Repayment_Schedule__c repaySch : pRepayScheduleList){
            fsCore__Calculator_Repayment_Schedule__c calcRepaySch = new fsCore__Calculator_Repayment_Schedule__c();

            calcRepaySch.fsCore__Number_Of_Payments__c = repaySch.Number_Of_Payments__c;
            calcRepaySch.fsCore__Payment_Amount__c = repaySch.Payment_Amount__c;
            calcRepaySch.fsCore__Start_Date__c = repaySch.Start_Date__c;
            calcRepaySch.fsCore__Is_Predefined_Payment__c = repaySch.Is_Predefined_Payment__c;
            
            calcRepaySchtList.add(calcRepaySch);
        }
        
        mCalcObject.setRepaymentSchedule(calcRepaySchtList);
        return this;
    }

    public ContractCalculatorBuilder setRepaymentDetails(List<Contract_Repayment__c> pRepayDetailList){
        List<fsCore__Calculator_Repayment_Detail__c> calcRepayDtlList = new List<fsCore__Calculator_Repayment_Detail__c>();
        
        for (Contract_Repayment__c repayDtl : pRepayDetailList){
            fsCore__Calculator_Repayment_Detail__c calcRepayDtl = new fsCore__Calculator_Repayment_Detail__c();

            calcRepayDtl.fsCore__Payment_Number__c = repayDtl.Payment_Number__c;
            calcRepayDtl.fsCore__Payment_Date__c = repayDtl.Due_Date__c;
            calcRepayDtl.fsCore__Payment_Amount__c = repayDtl.Due_Amount__c;
            calcRepayDtl.fsCore__Opening_Balance_Amount__c = repayDtl.Opening_Balance_Amount__c;
            calcRepayDtl.fsCore__Principal_Amount__c = repayDtl.Principal_Due_Amount__c;
            calcRepayDtl.fsCore__Interest_Amount__c = repayDtl.Interest_Due_Amount__c;
            calcRepayDtl.fsCore__Fee_Amount__c = repayDtl.Periodic_Fee_Due_Amount__c;
            calcRepayDtl.fsCore__Closing_Balance_Amount__c = repayDtl.Closing_Balance_Amount__c;
            
            calcRepayDtlList.add(calcRepayDtl);
        }
        
        mCalcObject.setRepaymentDetails(calcRepayDtlList);
        return this;
    }
    
}
