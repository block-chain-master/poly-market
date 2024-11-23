// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Vote {
        string question; // 투표 질문
        string imageURL; // 이미지 URL
        string[] options; // 선택지 배열
        uint startTime; // 투표 시작 시간
        uint endTime; // 투표 종료 시간
        address creator; // 투표 생성자
        uint totalBetAmount; // 총 배팅 금액
        bool ended; // 투표 종료 여부
        mapping(address => uint) userBets; // 사용자 주소 -> 배팅 금액
        mapping(uint => uint) votes; // 선택지별 투표 수
    }

    uint public voteCount; // 총 투표 종류 수
    mapping(uint => Vote) public votes; // 투표 ID로 투표 정보 접근

    // 투표 생성 이벤트
    event VoteCreated(uint voteId, string question, string imageURL, string[] options, uint startTime, uint endTime);

    // 투표 종료 이벤트
    event VoteEnded(uint voteId, address[] winners, uint totalReward, uint creatorReward);

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

        // 기존 배팅에 추가
        votes[voteId].userBets[msg.sender] += msg.value;
        votes[voteId].votes[optionIndex]++; // 선택지 투표 수 증가
        votes[voteId].totalBetAmount += msg.value; // 총 배팅 금액 증가
    }

    // 투표 종료 및 보상 분배
    function endVote(uint voteId) public {
        require(votes[voteId].creator == msg.sender, "Only the creator can end the vote");
        require(block.timestamp >= votes[voteId].endTime, "Voting is still ongoing");
        require(!votes[voteId].ended, "Vote has already ended");

        // 투표 종료 처리
        votes[voteId].ended = true;

        uint totalPool = votes[voteId].totalBetAmount; // 전체 배팅 금액
        uint creatorReward = totalPool / 1000; // 0.1% 수수료
        uint remainingPool = totalPool - creatorReward; // 승자들에게 분배할 금액

        // 투표 생성자에게 수수료 지급
        payable(votes[voteId].creator).transfer(creatorReward);

        // 가장 많은 투표를 받은 옵션을 찾기
        uint winningVotes = 0;
        uint winningOption = 0;
        for (uint i = 0; i < votes[voteId].options.length; i++) {
            if (votes[voteId].votes[i] > winningVotes) {
                winningVotes = votes[voteId].votes[i];
                winningOption = i;
            }
        }

        // 승자 목록 추출
        address[] memory winners = getWinners(voteId, winningOption);

        uint totalWinnersBet = 0;
        for (uint i = 0; i < winners.length; i++) {
            totalWinnersBet += votes[voteId].userBets[winners[i]];
        }

        // 승자들에게 보상 분배
        for (uint i = 0; i < winners.length; i++) {
            uint winnerShare = (votes[voteId].userBets[winners[i]] * remainingPool) / totalWinnersBet;
            payable(winners[i]).transfer(winnerShare);
        }

        emit VoteEnded(voteId, winners, totalPool, creatorReward);
    }

    // 승자 목록 반환
    function getWinners(uint voteId, uint winningOption) internal view returns (address[] memory) {
        address[] memory users = getUsers(voteId); // 모든 참여자 주소
        uint winnerCount = 0;
        address[] memory winners = new address[](users.length);

        for (uint i = 0; i < users.length; i++) {
            if (votes[voteId].userBets[users[i]] > 0 && votes[voteId].votes[winningOption] > 0) {
                winners[winnerCount] = users[i];
                winnerCount++;
            }
        }

        // 실제 승자 배열의 크기로 새 배열 반환
        address[] memory finalWinners = new address[](winnerCount);
        for (uint i = 0; i < winnerCount; i++) {
            finalWinners[i] = winners[i];
        }

        return finalWinners;
    }

    // 투표 참여한 사용자 목록 반환
    function getUsers(uint voteId) internal view returns (address[] memory) {
        uint totalVoters = 0;
        uint[] memory results = getResults(voteId);

        for (uint i = 0; i < results.length; i++) {
            totalVoters += results[i];
        }

        address[] memory users = new address[](totalVoters);
        uint userCount = 0;

        for (uint i = 0; i < results.length; i++) {
            for (uint j = 0; j < totalVoters; j++) {
                if (votes[voteId].userBets[users[j]] > 0) {
                    users[userCount] = users[j];
                    userCount++;
                }
            }
        }

        address[] memory finalUsers = new address[](userCount);
        for (uint i = 0; i < userCount; i++) {
            finalUsers[i] = users[i];
        }

        return finalUsers;
    }

    // 결과 가져오기
    function getResults(uint voteId) public view returns (uint[] memory) {
        require(votes[voteId].creator != address(0), "Vote does not exist");

        uint[] memory results = new uint[](votes[voteId].options.length);
        for (uint i = 0; i < votes[voteId].options.length; i++) {
            results[i] = votes[voteId].votes[i];
        }
        return results;
    }
}
