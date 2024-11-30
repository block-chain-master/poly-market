<template>
  <div v-if="isLogin" class="container">
    <h1>폴리마켓 지갑</h1>
    <div class="wallet-info">
      <template v-if="!isConnected">
        <button @click="connectWallet">MetaMask 연결</button>
      </template>
      <template v-else>
        <div>
          <p>주소: {{ address }}</p>
          <p>잔액: {{ balance }} ETH</p>
          <p>네트워크: {{ network }}</p>
          <div class="eth-price">
            <p>현재 이더리움 가격: ${{ ethPrice }}</p>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { ethers } from 'ethers';
import {useAuthStore} from "~/storage/auth.js";

const authStore = useAuthStore()

const isLogin = authStore.isLoggedIn;
const ethPrice = ref(0.00);

const isConnected = ref(false);
const address = ref('');
const balance = ref('');
const network = ref('');

const getEthPrice = async () => {
  try {
    // Ganache의 기본 URL. 필요에 따라 변경하세요.
    const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545');

    // 체인 ID를 확인하여 로컬 환경인지 판단
    const network = await provider.getNetwork();

    if (network.chainId === 1337) { // Ganache의 기본 체인 ID
      // 로컬 환경일 경우 하드코딩된 가격 사용
      ethPrice.value = (2000 + Math.random() * 100).toFixed(2);
    } else {
      // 실제 네트워크일 경우 기존 로직 사용
      const aggregatorV3InterfaceABI = [
        {
          inputs: [],
          name: "latestRoundData",
          outputs: [
            { internalType: "uint80", name: "roundId", type: "uint80" },
            { internalType: "int256", name: "answer", type: "int256" },
            { internalType: "uint256", name: "startedAt", type: "uint256" },
            { internalType: "uint256", name: "updatedAt", type: "uint256" },
            { internalType: "uint80", name: "answeredInRound", type: "uint80" }
          ],
          stateMutability: "view",
          type: "function"
        }
      ];
      const addr = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";
      const priceFeed = new ethers.Contract(addr, aggregatorV3InterfaceABI, provider);
      const roundData = await priceFeed.latestRoundData();
      ethPrice.value = (roundData.answer.toNumber() / 100000000).toFixed(2);
    }
  } catch (error) {
    console.error("이더리움 가격을 가져오는 데 실패했습니다:", error);
  }
};

const connectWallet = async () => {
  if (typeof window.ethereum !== 'undefined') {
    try {
      // MetaMask 계정 요청
      await window.ethereum.request({ method: 'eth_requestAccounts' });

      // 연결된 계정 주소 가져오기
      const accounts = await window.ethereum.request({ method: 'eth_accounts' });
      address.value = accounts[0];

      // 잔액 가져오기
      const balanceWei = await window.ethereum.request({
        method: 'eth_getBalance',
        params: [address.value, 'latest']
      });
      balance.value = parseInt(balanceWei, 16) / 1e18; // Wei를 ETH로 변환
      // 네트워크 정보 가져오기
      const chainId = await window.ethereum.request({ method: 'eth_chainId' });
      network.value = getNetworkName(chainId);

      setTimeout(() => {
        isConnected.value = true;
      },1);
    } catch (error) {
      console.error('MetaMask 연결 오류:', error);
    }
  } else {
    console.error('MetaMask가 설치되어 있지 않습니다.');
  }
};

const getNetworkName = (chainId) => {
  switch (chainId) {
    case '0x1':
      return 'Ethereum Mainnet';
    case '0x3':
      return 'Ropsten Testnet';
    case '0x4':
      return 'Rinkeby Testnet';
    case '0x5':
      return 'Goerli Testnet';
    case '0x539': // Ganache 기본 체인 ID
      return 'Ganache Local';
    default:
      return 'Unknown Network';
  }
};

onMounted(() => {
  // 페이지 로드 시 자동으로 연결 시도
  connectWallet();
  getEthPrice();
  // 10초마다 가격 업데이트
  setInterval(getEthPrice, 10000);
});
</script>

<style scoped>
.container {
  max-width: 500px;
  margin: 0 auto;
  padding: 20px;
  border: 1px solid #cccccc;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  background-color: #f9f9f9;
}

h1 {
  text-align: center;
  color: #111111;
}

.wallet-info {
  margin-bottom: 20px;
}

.wallet-info p {
  font-size: 18px;
}

input[type="number"] {
  width: 100%;
  padding: 10px;
  margin: 10px 0;
  border: 1px solid #cccccc;
  border-radius: 4px;
}

button {
  width: 100%;
  padding: 10px;
  background-color: #333333;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
}

button:hover {
  background-color: #555555;
}
.container {
  max-width: 500px;
  margin: 20px auto; /* 상단 여백 추가 */
  padding: 20px;
  border: 1px solid #cccccc;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  background-color: #ffffff; /* 배경색을 흰색으로 변경 */
  color: #333333; /* 텍스트 색상 명시 */
  position: relative; /* 위치 지정 */
  z-index: 1; /* z-index 추가 */
  min-height: 300px; /* 최소 높이 설정 */
}

</style>