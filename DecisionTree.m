%{

-This program implements and solves a decision tree for maximimizing
market share using results of Yes/No surveys. 

-Surveys are conducted over 3 phases; after every phase of surveys,
a decision is made whether to market the product, continue to the next phase
or terminate the product.

-A layout of the decision tree solved is shown in "TreeLayout.jpeg"
Details of this project can be found in "Project Report.pdf"
The survey strategy is provided as a table in "Survey Strategy.pdf"

-This code can be modified for any number of surveys per phase but can only deal
with a maximum of 3 phases.

%}


%Parameters
maxPhase = 3; %maximum number of survey phases
surveySize = 55; %number of surveys per phase
m=[0.1 0.2 0.3]; %market share percentages
yesVotes=zeros(1,3); %vector to store number of yes votes per phase
MarketSize = 400*120; %market units
CostPerMarketUnit = 2.6; %Cost price
SellingPerMarketUnit = 5.19; %Selling Price
CostPerPhase = CostPerMarketUnit*surveySize + 200; %$2.6 per person + %200 set up cost
ProfitPerMarketUnit = (SellingPerMarketUnit - CostPerMarketUnit);
marketProb = zeros(maxPhase+1,length(m)); %vector to store p(market share)

probYesVotesByMarket = zeros(maxPhase,length(m));

%underlying probabilities of market share for survey phase 1
marketProb(1,:)= [0.25 0.5 0.25];
sumProb=0;

for p1=0:surveySize %number of yes votes in phase 1
    for p2=0:surveySize %number of yes votes in phase 2
        for p3=0:surveySize %number of yes votes in phase 3
            yesVotes = [p1 p2 p3];
            %given number of yes votes per phase,
			
            for i=1:maxPhase
                %calculate probability of this combination of yes votes
                sumProb=0;
				
                for j=1:length(m)
                    probYesVotesByMarket(i,j)= marketProb(i,j)...
					*nchoosek(surveySize,yesVotes(i))*(m(j)^yesVotes(i))...
										*((1-m(j))^(surveySize-yesVotes(i)));
										
                    sumProb = sumProb + probYesVotesByMarket(i,j);
                end
                probYesVotes(p1+1,p2+1,p3+1,i)=sumProb;
                expectedMarket = 0;
                
                %calculate expected market share
                for j=1:length(m)
                    marketProb(i+1,j)= probYesVotesByMarket(i,j)/sumProb;
                    expectedMarket = expectedMarket+(m(j)*marketProb(i+1,j));
                end
                
                %calculate market value given expected market share
                EMV(p1+1,p2+1,p3+1,i)=expectedMarket;
            end
        end
    end
end

%Decision Making
%MCT: market=1, continue=2, terminate=3
%stores decisions at every phase for all combinations of votes
%range of yes votes = 0 to surveySize (total # = surveySize+1)

%initialize all to 0
MCT = zeros(surveySize+1,surveySize+1,surveySize+1,maxPhase);

%Evaluate expected value of Phase 3
for p1=0:surveySize
    for p2=0:surveySize
        CV=0; %variable to store expected value of continuing to next phase
        for p3=0:surveySize
            TerminateValue = -1*CostPerPhase*3;
            TerminateValue = utility(TerminateValue); %remove if calculating expected profit
            MarketValue = MarketSize*(EMV(p1+1,p2+1,p3+1,3)*ProfitPerMarketUnit - CostPerMarketUnit)- CostPerPhase*3;
            MarketValue = utility(MarketValue); %remove if calculating expected profit
            if(MarketValue > TerminateValue)
                MCT(p1+1,p2+1,p3+1,3)=1; %Market the product immediately
                EV(p1+1,p2+1,p3+1,3)=MarketValue; %Expected market share
            else
                MCT(p1+1,p2+1,p3+1,3)=3; %Terminate the product
                EV(p1+1,p2+1,p3+1,3)=TerminateValue;
            end
            %Expected value of each branch
            CV=CV+(probYesVotes(p1+1,p2+1,p3+1,3)*EV(p1+1,p2+1,p3+1,3));
        end
        %Expected value of Phase 3 for given # of votes in Phases 1 & 2
        %Used to decide if Phase 3 should be conducted
        ContinueValue(p1+1,p2+1,1,2)=CV;
    end
end

%Expected Value of Phase 2
for p1=0:surveySize
    CV=0;
    for p2=0:surveySize
        for p3=0:surveySize
            TerminateValue = -1*CostPerPhase*2;
            TerminateValue = utility(TerminateValue); %remove if calculating expected profit
            MarketValue = MarketSize*(EMV(p1+1,p2+1,p3+1,2)*ProfitPerMarketUnit - CostPerMarketUnit)- CostPerPhase*2;
            MarketValue = utility(MarketValue);  %remove if calculating expected profit
            if ((MarketValue > TerminateValue) && (MarketValue > ContinueValue(p1+1,p2+1,1,2)))
                MCT(p1+1,p2+1,p3+1,2)=1; %Market
                EV(p1+1,p2+1,p3+1,2)=MarketValue;
            elseif ((ContinueValue(p1+1,p2+1,1,2)> MarketValue) && (ContinueValue(p1+1,p2+1,1,2)>TerminateValue))
                MCT(p1+1,p2+1,p3+1,2)=2; %continue
                EV(p1+1,p2+1,p3+1,2)=ContinueValue(p1+1,p2+1,1,2);
            else
                MCT(p1+1,p2+1,p3+1,2)=3; %Terminate
                EV(p1+1,p2+1,p3+1,2)=TerminateValue;
            end
        end
        
        %Expected value of each branch
        CV=CV+(probYesVotes(p1+1,p2+1,p3+1,2)*EV(p1+1,p2+1,p3+1,2));
    end
    %Expected value of Phase 2 for given # of votes in Phase 1
    ContinueValue(p1+1,1,1,1)=CV;
end

%Expected Value of Phase 1
for p1=0:surveySize
    for p2=0:surveySize
        for p3=0:surveySize
            TerminateValue = -1*CostPerPhase*1;
            TerminateValue = utility(TerminateValue); %remove if calculating expected profit
            MarketValue = MarketSize*(EMV(p1+1,p2+1,p3+1,1)*ProfitPerMarketUnit - CostPerMarketUnit)- CostPerPhase*1;
            MarketValue = utility(MarketValue); %remove if calculating expected profit
            if ((MarketValue > TerminateValue) && (MarketValue > ContinueValue(p1+1,1,1,1)))
                MCT(p1+1,p2+1,p3+1,1)=1; %Market
                EV(p1+1,p2+1,p3+1,1)=MarketValue;
            elseif ((ContinueValue(p1+1,1,1,1)> MarketValue) && (ContinueValue(p1+1,1,1,1)>TerminateValue))
                MCT(p1+1,p2+1,p3+1,1)=2; %Continue
                EV(p1+1,p2+1,p3+1,1)=ContinueValue(p1+1,1,1,1);
            else
                MCT(p1+1,p2+1,p3+1,1)=3; %Terminate
                EV(p1+1,p2+1,p3+1,1)=TerminateValue;
            end
        end
    end
end

datasave=[];

i=1; %Only Phase 1
for p1=0:surveySize
    a=-1; %print -1 to show Phase 2 & 3 have not been conducted
    datasave=[datasave;p1 a a i EMV(p1+1,p2+1,p3+1,i) MCT(p1+1,p2+1,p3+1,i) EV(p1+1,p2+1,p3+1,i)];
end

i=2; %Phase 1 and Phase 2
for p1=0:surveySize
    for p2=0:surveySize
        if MCT(p1+1,1,1,1) == 2 %if first round is not terminated 
            a=-1; %print -1 to show Phase 3 has not been conducted
            datasave=[datasave;p1 p2 a i EMV(p1+1,p2+1,p3+1,i) MCT(p1+1,p2+1,p3+1,i) EV(p1+1,p2+1,p3+1,i)];
        end 
    end
end

i=3; %Phases 1,2 and 3
for p1=0:surveySize
    for p2=0:surveySize
        for p3=0:surveySize
            %if first and 2nd rounds have not been terminated
            if (MCT(p1+1,1,1,1) == 2) && (MCT(p1+1,p2+1,1,2)==2) 
                datasave=[datasave;p1 p2 p3 i EMV(p1+1,p2+1,p3+1,i) MCT(p1+1,p2+1,p3+1,i) EV(p1+1,p2+1,p3+1,i)];
            end 
        end
    end
end

disp(datasave)

%function to calculate utility value
function y = utility(x)
    y = 0.01004136 + 0.00001644439*x + 1.067261*(10^-10)*x^2;
end
