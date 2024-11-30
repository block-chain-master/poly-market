<template>
  <div class="container">
    <!-- 투표 진행 중인 섹션 추가 -->
    <div class="voting-section">
      <h2 class="section-title">진행 중인 투표</h2>
      <div class="voting-card">
        <div class="voting-card-header">
          <img :src="activeVote.icon" :alt="activeVote.title" class="voting-card-icon">
          <h3 class="voting-card-title">{{ activeVote.title }}</h3>
        </div>
        <div class="voting-card-body">
          <div v-for="(option, optionIndex) in opListVal.value" :key="optionIndex" class="voting-option">
            <span class="voting-option-name">{{ option.option }}</span>
            <div class="voting-progress-bar">
              <div class="voting-progress" :style="{ width: (option.percent ? option.percent : 0) + '%' }"></div>
            </div>
            <span class="voting-option-percentage">{{ option.percent ? option.percent : 0 }}%</span>
            <button v-if="isLogin" class="btn btn-vote" @click="castVote(0n, option.id, optionIndex)">투표하기</button>
          </div>
        </div>
        <div class="voting-card-footer">
          <div class="time-left-container">
            <span class="time-icon">⏳</span>
            <span class="voting-time-left">{{ formattedTimeLeft }}</span>
            <span class="time-remaining">남음</span>
          </div>
        </div>
      </div>
    </div>

    <div class="grid">
      <div v-for="(item, index) in items" :key="index" class="card">
        <div class="card-header">
          <img :src="item.icon" :alt="item.title" class="card-icon">
          <h2 class="card-title">{{ item.title }}</h2>
        </div>
        <div class="card-body">
          <div v-for="(option, optionIndex) in item.options" :key="optionIndex" class="option">
            <span class="option-name">{{ option.name }}</span>
            <span class="option-percentage">{{ option.percentage }}%</span>
            <div class="option-buttons">
              <button class="btn btn-yes">Yes</button>
              <button class="btn btn-no">No</button>
            </div>
          </div>
        </div>
        <div class="card-footer">
          <span class="volume">{{ item.volume }} Vol.</span>
          <span class="comments">{{ item.comments }} comments</span>
        </div>
      </div>
    </div>

    <div class="fixed-bottom">
      <button class="force-end-vote-btn" @click="voteForceEnd">투표 강제 종료</button>
    </div>
  </div>
</template>

<script setup>
import Web3 from 'web3';
import {useAuthStore} from "~/storage/auth.js";

const authStore = useAuthStore()

const web3 = new Web3(Web3.givenProvider || "http://localhost:8545");
const contractABI = [
  {
    "inputs": [
      {
        "internalType": "address[]",
        "name": "recipients",
        "type": "address[]"
      },
      {
        "internalType": "uint256[]",
        "name": "amounts",
        "type": "uint256[]"
      }
    ],
    "name": "batchTransfer",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "voteId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "optionIndex",
        "type": "uint256"
      }
    ],
    "name": "castVote",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "question",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "imageURL",
        "type": "string"
      },
      {
        "internalType": "string[]",
        "name": "options",
        "type": "string[]"
      },
      {
        "internalType": "uint256",
        "name": "duration",
        "type": "uint256"
      }
    ],
    "name": "createVote",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address[]",
        "name": "recipients",
        "type": "address[]"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "amounts",
        "type": "uint256[]"
      }
    ],
    "name": "EtherTransferred",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "voteId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "question",
        "type": "string"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "imageURL",
        "type": "string"
      },
      {
        "indexed": false,
        "internalType": "string[]",
        "name": "options",
        "type": "string[]"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "startTime",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "endTime",
        "type": "uint256"
      }
    ],
    "name": "VoteCreated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "voteId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "winningOption",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "totalBetAmount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "address[]",
        "name": "winners",
        "type": "address[]"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "amounts",
        "type": "uint256[]"
      }
    ],
    "name": "VoteEnded",
    "type": "event"
  },
  {
    "inputs": [],
    "name": "getAllVotes",
    "outputs": [
      {
        "internalType": "uint256[]",
        "name": "voteIds",
        "type": "uint256[]"
      },
      {
        "internalType": "string[]",
        "name": "questions",
        "type": "string[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "voteId",
        "type": "uint256"
      }
    ],
    "name": "getVoteInfos",
    "outputs": [
      {
        "internalType": "string",
        "name": "question",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "imageURL",
        "type": "string"
      },
      {
        "internalType": "string[]",
        "name": "options",
        "type": "string[]"
      },
      {
        "internalType": "uint256[]",
        "name": "votesPerOption",
        "type": "uint256[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "voteId",
        "type": "uint256"
      }
    ],
    "name": "getVoteResults",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "winningOption",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalBetAmount",
        "type": "uint256"
      },
      {
        "internalType": "address[]",
        "name": "winners",
        "type": "address[]"
      },
      {
        "internalType": "uint256[]",
        "name": "amounts",
        "type": "uint256[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "voteCount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "votes",
    "outputs": [
      {
        "internalType": "string",
        "name": "question",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "imageURL",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "startTime",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "endTime",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "creator",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "totalBetAmount",
        "type": "uint256"
      },
      {
        "internalType": "bool",
        "name": "ended",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
];
const contractAddress = '0x57E97099967e8EC46f078594232e167ea5ED54a9';
const voteList = reactive({});
const opListVal = reactive({});

const isLogin = authStore.isLoggedIn;

// 스마트 계약 인스턴스 생성
const votingContract = new web3.eth.Contract(contractABI, contractAddress);

// 투표 생성 함수
async function createVote(question, imageURL, options, duration) {
  try {
    const accounts = await web3.eth.getAccounts();
    const feeData = await web3.eth.calculateFeeData();

    // 가스 추정
    const gasEstimate = await votingContract.methods.createVote(question, imageURL, options, duration).estimateGas({from: accounts[0]});

    // 가스 한도를 추정치의 1.2배로 설정 (BigInt 사용)
    const gasLimit = BigInt(Math.floor(Number(gasEstimate) * 1.2));

    const tx = await votingContract.methods.createVote(question, imageURL, options, duration).send({
      from: accounts[0],
      gas: gasLimit,
      maxFeePerGas: feeData.maxFeePerGas,
      maxPriorityFeePerGas: feeData.maxPriorityFeePerGas
    });
  } catch (error) {
    console.error("Error creating vote:", error);
  }
}

// 투표 참여 함수
async function castVote(voteId, optionIndex, accountIdx) {
  try {
    const accounts = await web3.eth.getAccounts();
    const tx = await votingContract.methods.castVote(voteId, optionIndex).send({
      from: accounts[accountIdx > 8 ? 0 : accountIdx],
      value: web3.utils.toWei('0.1', 'ether'),
      gas: 300000
    });

    if (tx.transactionHash) {
      const voteResult = await getVoteInfos(voteId);
      if (voteResult) {
        const {options, votesPerOption} = voteResult;
        const opList = createOpList(options, votesPerOption);
        opListVal.value = {};
        opListVal.value = opList;
      }
    }
  } catch (error) {
    console.error('Error casting vote:', error);
  }
}

async function vote(voteId) {
  try {
    const result = await votingContract.methods.votes(voteId).call();
    return result;
  } catch (error) {
    console.error('Error fetching votes:', error);
  }
}

async function getVoteInfos(voteId) {
  return await votingContract.methods.getVoteInfos(voteId).call()
}

// 투표 결과 조회 함수
async function getVoteResults(voteId) {
  return await votingContract.methods.getVoteResults(voteId).call()
}

// 모든 투표 조회 함수
async function getAllVotes() {
  try {
    return await votingContract.methods.getAllVotes().call();
  } catch (error) {
    console.error('Error fetching votes:', error);
  }
}

// 이벤트 리스닝
votingContract.events.VoteCreated({}, (error, event) => {
  console.log('New vote created:', event.returnValues);
});

votingContract.events.VoteEnded({}, (error, event) => {
  console.log('Vote ended:', event.returnValues);
});

const targetDate = new Date('2024-11-30 19:00:00').getTime();
const timeLeft = ref('')
const formattedTimeLeft = ref('')
let timer


const updateTimer = () => {
  const now = new Date().getTime()
  const difference = targetDate - now

  if (difference > 0) {
    const days = Math.floor(difference / (1000 * 60 * 60 * 24))
    const hours = Math.floor((difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((difference % (1000 * 60)) / 1000)

    timeLeft.value = `${days}일 ${hours}시간 ${minutes}분 ${seconds}초`
    formattedTimeLeft.value = `D-${days} ${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
  } else {
    timeLeft.value = 'D-day가 지났습니다!'
    formattedTimeLeft.value = 'D-day가 지났습니다!'
    clearInterval(timer)
  }
}

onMounted(async () => {
  updateTimer()
  timer = setInterval(updateTimer, 1000)
  let votes = await getAllVotes();
  // 8.19
  console.log(votes)
  if (!votes.voteIds.length) {
    votes = await createVote('가장많이 오를것같은 코인은?', `https://i.namu.wiki/i/u6i7DVoL_l46S9Hyhltbhn3zdi9gzSJUWFyY6mRHH89RmIYRUPEVSydgDFYmg_WalAqY-y03TcG3Pb3s-o1xSw.webp`, ["도지코인", "비트코인", "이더리움", "솔라나", "폴리곤", "리플", "시바이누", "아크"], 259200);
    console.log(votes)
  }
  const voteResult = await getVoteInfos(votes?.voteIds[0]);
  if (voteResult) {
    const {options, votesPerOption} = voteResult;

    const opList = createOpList(options, votesPerOption);
    opListVal.value = opList;
  }
})

const createOpList = (options, votesPerOption) => {
  const totalVotes = votesPerOption.reduce((sum, votes) => sum + BigInt(votes), BigInt(0));

  const list = options.map((option, index) => {
    const count = Number(votesPerOption[index]);
    const percent = totalVotes > 0
        ? Number((BigInt(votesPerOption[index]) * BigInt(100)) / totalVotes)
        : 0;

    return {
      option,
      count,
      percent,
      id: index
    };
  });

  // percent 기준으로 내림차순 정렬
  return list.sort((a, b) => b.percent - a.percent);
};

const activeVote = {
  icon: 'https://i.namu.wiki/i/u6i7DVoL_l46S9Hyhltbhn3zdi9gzSJUWFyY6mRHH89RmIYRUPEVSydgDFYmg_WalAqY-y03TcG3Pb3s-o1xSw.webp',
  title: '가장많이 오를것같은 코인은?',
  options: [
    { name: '도지코인', percentage: 25 },
    { name: '비트코인', percentage: 23 },
    { name: '이더리움', percentage: 12 },
    { name: '솔라나', percentage: 11 },
    { name: '폴리곤', percentage: 10 },
    { name: '리플', percentage: 9 },
    { name: '시바이누', percentage: 6 },
    { name: '아크', percentage: 4 },
  ],
  timeLeft: '3일'
};

const items = [
  // 여기에 8개의 아이템 데이터를 넣으세요
  {
    icon: 'https://polymarket.com/_next/image?url=https%3A%2F%2Fpolymarket-upload.s3.us-east-2.amazonaws.com%2Ftrump-pardons-M-H-ZTXh777o.jpg&w=96&q=75',
    title: 'Who will Trump pardon in first 100 days?',
    options: [
      { name: 'dance', percentage: 60 },
      { name: 'showing', percentage: 40 },
      { name: 'singing', percentage: 40 },
      { name: 'playing', percentage: 40 },
      { name: 'eating', percentage: 40 },
      { name: 'sleeping', percentage: 40 },
      { name: 'calling', percentage: 40 },
      { name: 'talking', percentage: 40 },
      { name: 'walking', percentage: 40 },
      { name: 'running', percentage: 40 },
      { name: 'jumping', percentage: 40 },
      { name: 'swimming', percentage: 40 },
      { name: 'flying', percentage: 40 },
      { name: 'driving', percentage: 40 },
      { name: 'riding', percentage: 40 },
      { name: 'cycling', percentage: 40 },
      { name: 'skating', percentage: 40 },
      { name: 'skiing', percentage: 40 },
      { name: 'snowboarding', percentage: 40 },
      { name: 'surfing', percentage: 40 },
      { name: 'diving', percentage: 40 },
      { name: 'fishing', percentage: 40 },
      { name: 'hunting', percentage: 40 },
      { name: 'shooting', percentage: 40 },
    ],
    volume: '$1.2m',
    comments: 120
  },
  {
    icon: 'https://polymarket.com/_next/image?url=https%3A%2F%2Fpolymarket-upload.s3.us-east-2.amazonaws.com%2Fchampions-league-winner-2025-F-QYbKsrHt_E.jpg&w=96&q=75',
    title: 'Champions League Winner',
    options: [
      { name: 'Manchester City', percentage: 60 },
      { name: 'Barcelona', percentage: 40 },
      { name: 'Real Madrid', percentage: 40 },
      { name: 'Arsenal', percentage: 40 },
    ],
    volume: '$1.2m',
    comments: 120
  },
  {
    icon: 'https://polymarket.com/_next/image?url=https%3A%2F%2Fpolymarket-upload.s3.us-east-2.amazonaws.com%2FRepetitive-markets%2Fpremier%2Bleague.jpg&w=96&q=75',
    title: 'Premier League Winner',
    options: [
      { name: 'Liverpool', percentage: 60 },
      { name: 'Manchester City', percentage: 40 },
      { name: 'Arsenal', percentage: 40 },
      { name: 'Chelsea', percentage: 40 },
      { name: 'Manchester United', percentage: 40 },
      { name: 'Tottenham Hotspur', percentage: 40 },
      { name: 'Leicester City', percentage: 40 },
      { name: 'Everton', percentage: 40 },
      { name: 'West Ham United', percentage: 40 },
      { name: 'Aston Villa', percentage: 40 },
      { name: 'Newcastle United', percentage: 40 },
      { name: 'Crystal Palace', percentage: 40 },
      { name: 'Southampton', percentage: 40 },
      { name: 'Burnley', percentage: 40 },
      { name: 'Fulham', percentage: 40 },
    ],
    volume: '$1.2m',
    comments: 120
  },{
    icon: 'https://polymarket.com/_next/image?url=https%3A%2F%2Fpolymarket-upload.s3.us-east-2.amazonaws.com%2Fjerome%2Bpowell%2Bglasses1.png&w=96&q=75',
    title: 'Fed decision in December?',
    options: [
      { name: '75+ bps decrease', percentage: 20 },
      { name: '25+ bps decrease', percentage: 10 },
      { name: 'Other', percentage: 10 },
      { name: '50 bps decrease', percentage: 10 },
      { name: '25 bps decrease', percentage: 20 },
    ],
    volume: '$1.2m',
    comments: 120
  },
  {
    icon: 'https://polymarket.com/_next/image?url=https%3A%2F%2Fpolymarket-upload.s3.us-east-2.amazonaws.com%2Fradioactive.png&w=96&q=100',
    title: 'Will a nuclear weapon detonate in 2024?',
    options: [
      { name: 'yes', percentage: 50 },
      { name: 'no', percentage: 50 },
    ],
    volume: '$1.2m',
    comments: 120
  },
  {
    icon: 'https://polymarket.com/_next/image?url=https%3A%2F%2Fpolymarket-upload.s3.us-east-2.amazonaws.com%2Fisrael-x-hezbollah-ceasefire-in-2024-SleLk5Jat7iT.jpg&w=96&q=100',
    title: 'Israel x Hezbollah Ceasefire in 2024?',
    options: [
      { name: 'yes', percentage: 60 },
      { name: 'no', percentage: 40 },
    ],
    volume: '$1.2m',
    comments: 120
  },
  {
    icon: 'https://polymarket.com/_next/image?url=https%3A%2F%2Fpolymarket-upload.s3.us-east-2.amazonaws.com%2Fbtc%2Bparty.png&w=96&q=100',
    title: 'Will Bitcoin hit $100k in 2024?',
    options: [
      { name: 'yes', percentage: 60 },
      { name: 'no', percentage: 40 },
    ],
    volume: '$1.2m',
    comments: 120
  },
  {
    icon: 'https://polymarket.com/_next/image?url=https%3A%2F%2Fpolymarket-upload.s3.us-east-2.amazonaws.com%2Fsuperbowl-champion-2025-0QHIP2qbyyH0.png&w=96&q=100',
    title: 'Super Bowl Champion 2025',
    options: [
      { name: 'Lions', percentage: 24 },
      { name: 'Chiefs', percentage: 19 },
      { name: 'Eagles', percentage: 19 },
      { name: 'Ravens', percentage: 19 },
      { name: '49ers', percentage: 19 },
    ],
    volume: '$1.2m',
    comments: 120
  },
];

const voteForceEnd = async () => {
  try {
    const result = await getVoteResults(0);
    console.log("Vote results:", result);

    const recipients = result[2]; // winners 배열
    const amounts = result[3]; // amounts 배열

    // Wei를 Ether로 변환
    const amountsInEther = amounts.map(amount => web3.utils.fromWei(amount, 'ether'));

    console.log("Recipients:", recipients);
    console.log("Amounts (in Ether):", amountsInEther);

    // 컨트랙트의 batchTransfer 함수 호출
    const accounts = await web3.eth.getAccounts();
    await votingContract.methods.batchTransfer(recipients, amounts).send({
      from: accounts[0],
      gas: 3000000 // 가스 한도 설정
    });

    console.log("Batch transfer completed successfully");
  } catch (error) {
    console.error("Error in voteForceEnd:", error);
  }
};
</script>

<style scoped>
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  padding-bottom: 60px;
}

.grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

.card {
  background-color: var(--colors-cardFill, #2C3F4F);
  border-radius: 8px;
  border: 1px solid var(--colors-cardBorder, #344452);
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  height: 300px; /* 카드의 고정 높이 설정 */
}

.card-header {
  padding: 12px;
  display: flex;
  align-items: center;
}

.card-icon {
  width: 38px;
  height: 38px;
  border-radius: 4px;
  margin-right: 12px;
}

.card-title {
  font-size: 16px;
  font-weight: bold;
  color: var(--colors-shadeBlack, #ffffff);
  margin: 0;
}

.card-body {
  flex-grow: 1;
  padding: 0 12px;
  overflow-y: auto; /* 세로 스크롤 추가 */
  max-height: 180px; /* 최대 높이 설정 */
}

.option {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.option-name {
  font-size: 14px;
  color: var(--colors-shadeBlack, #ffffff);
}

.option-percentage {
  font-size: 14px;
  font-weight: 500;
  color: var(--colors-shadeBlack, #ffffff);
}

.option-buttons {
  display: flex;
  gap: 4px;
}

.btn {
  padding: 4px 8px;
  font-size: 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-yes {
  background-color: var(--colors-green2, #27AE60);
  color: white;
}

.btn-no {
  background-color: var(--colors-red, #E64800);
  color: white;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  padding: 8px 12px;
  background-color: rgba(0, 0, 0, 0.1);
  font-size: 12px;
  color: var(--colors-shadeBlack, #ffffff);
}

/* 스크롤바 스타일링 (선택사항) */
.card-body::-webkit-scrollbar {
  width: 6px;
}

.card-body::-webkit-scrollbar-track {
  background: var(--colors-cardFill, #2C3F4F);
}

.card-body::-webkit-scrollbar-thumb {
  background-color: var(--colors-gray4, #425464);
  border-radius: 3px;
}

@media (max-width: 1200px) {
  .grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 900px) {
  .grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 600px) {
  .grid {
    grid-template-columns: 1fr;
  }
}

/* 추가 투표 섹션 스타일링 */
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.voting-section {
  margin-bottom: 40px; /* grid와의 간격 추가 */
}

.section-title {
  font-size: 24px;
  color: var(--colors-shadeBlack, #ffffff);
  margin-bottom: 20px;
}

.voting-card {
  background-color: var(--colors-cardFill, #2C3F4F);
  border-radius: 8px;
  border: 1px solid var(--colors-cardBorder, #344452);
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.voting-card-header {
  padding: 12px;
  display: flex;
  align-items: center;
}

.voting-card-icon {
  width: 32px;
  height: 32px;
  border-radius: 4px;
  margin-right: 12px;
}

.voting-card-title {
  font-size: 18px;
  font-weight: bold;
  color: var(--colors-shadeBlack, #ffffff);
  margin: 0;
}

.voting-card-body {
  padding: 12px;
}

.voting-option {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
}

.voting-option-name {
  flex: 1;
  font-size: 14px;
  color: var(--colors-shadeBlack, #ffffff);
}

.voting-progress-bar {
  flex: 2;
  height: 8px;
  background-color: var(--colors-gray5, #344452);
  border-radius: 4px;
  overflow: hidden;
  margin: 0 10px;
}

.voting-progress {
  height: 100%;
  background-color: var(--colors-polyBlue, #2D9CDB);
}

.voting-option-percentage {
  font-size: 12px;
  color: var(--colors-shadeMedium, #808080);
  width: 40px;
  text-align: right;
}

.btn-vote {
  background-color: var(--colors-polyBlue, #2D9CDB);
  color: white;
  border: none;
  padding: 4px 8px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  margin-left: 10px;
}
/**
.voting-card-footer {
  padding: 12px;
  background-color: rgba(0, 0, 0, 0.1);
}

.voting-time-left {
  font-size: 14px;
  color: var(--colors-shadeMedium, #808080);
}
**/
.voting-card-footer {
  padding: 12px 16px;
  background-color: #f0f0f0;
  border-top: 1px solid #e0e0e0;
  display: flex;
  justify-content: center;
  align-items: center;
}

.time-left-container {
  display: flex;
  align-items: center;
  background-color: #ffffff;
  border-radius: 20px;
  padding: 6px 12px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.time-icon {
  font-size: 18px;
  margin-right: 8px;
}

.voting-time-left {
  font-size: 16px;
  font-weight: bold;
  color: #333333;
}

.time-remaining {
  font-size: 14px;
  color: #666666;
  margin-left: 4px;
}
/* 기존 grid 및 card 스타일 유지 */
.grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

/* ... (나머지 기존 스타일) */

@media (max-width: 1200px) {
  .grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 900px) {
  .grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 600px) {
  .grid {
    grid-template-columns: 1fr;
  }
}

.force-end-vote-btn {
  position: fixed;
  bottom: 20px;
  right: 20px;
  background-color: #ff4136;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 10px 20px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
  z-index: 1000;
}

.force-end-vote-btn:hover {
  background-color: #e60000;
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
}

.force-end-vote-btn:hover {
  background-color: #e60000;
}
</style>