// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VotingSystem {

    // 배팅 정보 구조체
    struct Bet {
        address user;  // 배팅한 사용자 주소
        uint amount;   // 배팅 금액
    }

    // 투표 정보 구조체
    struct Vote {
        string question; // 투표 질문
        string imageURL; // 이미지 URL
        string[] options; // 선택지 배열
        uint startTime; // 투표 시작 시간
        uint endTime; // 투표 종료 시간
        address creator; // 투표 생성자
        uint totalBetAmount; // 총 배팅 금액
        bool ended; // 투표 종료 여부
        mapping(uint => Bet[]) bets; // 각 선택지에 대한 배팅 정보
    }

    uint public voteCount; // 총 투표 개수
    mapping(uint => Vote) public votes; // 투표 ID로 투표 정보 접근

    // 이벤트
    event VoteCreated(uint voteId, string question, string imageURL, string[] options, uint startTime, uint endTime);
    event VoteEnded(uint voteId, uint winningOption, uint totalBetAmount, address[] winners, uint[] amounts);
    event EtherTransferred(address[] recipients, uint[] amounts);

    // 투표 생성 함수
    function createVote(
        string memory question, 
        string memory imageURL, 
        string[] memory options, 
        uint duration
    ) public {
        require(options.length > 1, "At least two options are required");
        require(duration > 0, "Duration must be greater than 0");

        uint voteId = voteCount;
        Vote storage newVote = votes[voteId];
        newVote.question = question;
        newVote.imageURL = imageURL;
        newVote.creator = msg.sender;
        newVote.startTime = block.timestamp;
        newVote.endTime = block.timestamp + duration;

        // 선택지 추가
        for (uint i = 0; i < options.length; i++) {
            newVote.options.push(options[i]);
        }

        emit VoteCreated(voteId, question, imageURL, options, newVote.startTime, newVote.endTime);
        voteCount++;
    }

    // 투표 참여 및 배팅
    function castVote(uint voteId, uint optionIndex) public payable {
        require(votes[voteId].startTime <= block.timestamp, "Voting has not started yet");
        require(block.timestamp < votes[voteId].endTime, "Voting has ended");
        require(optionIndex < votes[voteId].options.length, "Invalid option");
        require(msg.value > 0, "You must bet some ether");

        // 배팅 정보를 옵션별로 기록
        Vote storage vote = votes[voteId];
        vote.bets[optionIndex].push(Bet({
            user: msg.sender,
            amount: msg.value
        }));

        vote.totalBetAmount += msg.value; // 총 배팅 금액 증가
    }

    // 투표 결과 가져오기
    function getVoteResults(uint voteId) public view returns (uint winningOption, uint totalBetAmount, address[] memory winners, uint[] memory amounts) {
        require(votes[voteId].creator != address(0), "Vote does not exist");

        uint totalPool = votes[voteId].totalBetAmount; // 전체 배팅 금액
        uint creatorReward = totalPool / 1000; // 0.1% 수수료
        uint remainingPool = totalPool - creatorReward; // 승자들에게 분배할 금액
       
        // 가장 많은 투표를 받은 옵션을 찾기
        uint winningVotes = 0;
        winningOption = 0;
        for (uint i = 0; i < votes[voteId].options.length; i++) {
            if (votes[voteId].bets[i].length > winningVotes) {
                winningVotes = votes[voteId].bets[i].length;
                winningOption = i;
            }
        }

        // 승자 목록 추출
        winners = getWinners(voteId, winningOption);
        uint totalWinnersBet = 0;
        for (uint i = 0; i < winners.length; i++) {
            totalWinnersBet += getTotalBetForUser(voteId, winners[i], winningOption);
        }

        amounts = new uint[](winners.length);
        // 승자들에게 보상 분배
        for (uint i = 0; i < winners.length; i++) {
            amounts[i] = (getTotalBetForUser(voteId, winners[i], winningOption) * remainingPool) / totalWinnersBet;
        }

        return (winningOption, totalPool, winners, amounts);
    }

    function getVoteInfos(uint voteId) public view returns (string memory question,string memory imageURL,string[] memory options,uint[] memory votesPerOption){
        question=votes[voteId].question;
        imageURL=votes[voteId].imageURL;
        options=votes[voteId].options;
        votesPerOption = new uint[](votes[voteId].options.length); // 각 옵션별 투표된 갯수를 저장할 배열 초기화

        // 각 옵션에 대해 투표된 갯수를 계산
        for (uint i = 0; i < votes[voteId].options.length; i++) {
            votesPerOption[i] = votes[voteId].bets[i].length; // 각 옵션에 대한 배팅 수 (투표된 갯수)
        }

        return (question,imageURL,options,votesPerOption);
    }

    // 승자 목록 반환
    function getWinners(uint voteId, uint winningOption) internal view returns (address[] memory) {
        address[] memory winnerAddresses = new address[](votes[voteId].bets[winningOption].length);
        uint winnerCount = 0;

        // 해당 옵션에 배팅한 사용자들을 모두 승자로 처리
        for (uint i = 0; i < votes[voteId].bets[winningOption].length; i++) {
            winnerAddresses[winnerCount] = votes[voteId].bets[winningOption][i].user;
            winnerCount++;
        }

        address[] memory finalWinners = new address[](winnerCount);
        for (uint i = 0; i < winnerCount; i++) {
            finalWinners[i] = winnerAddresses[i];
        }

        return finalWinners;
    }

    // 특정 사용자가 해당 옵션에 배팅한 총 금액을 반환
    function getTotalBetForUser(uint voteId, address user, uint optionIndex) internal view returns (uint) {
        uint totalBet = 0;
        for (uint i = 0; i < votes[voteId].bets[optionIndex].length; i++) {
            if (votes[voteId].bets[optionIndex][i].user == user) {
                totalBet += votes[voteId].bets[optionIndex][i].amount;
            }
        }
        return totalBet;
    }

    // 다중 이더 전송
    function batchTransfer(address[] memory recipients, uint[] memory amounts) public {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");

        for (uint i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(amounts[i]);
        }

        emit EtherTransferred(recipients, amounts);
    }

    // 모든 투표 리스트 반환
   function getAllVotes() public view returns (uint[] memory voteIds, string[] memory questions) {
        voteIds = new uint[](voteCount);
        questions = new string[](voteCount);

        for (uint i = 0; i < voteCount; i++) {
            voteIds[i] = i;
            questions[i] = votes[i].question;
        }
    }
}
