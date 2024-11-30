<template>
  <div class="login-container">
    <div class="login-box" :class="{ 'sign-up': !isSignIn }">
      <h2>{{ isSignIn ? '로그인' : '회원가입' }}</h2>
      <form @submit.prevent="isSignIn ? signIn() : signUp()">
        <div class="input-group" v-if="!isSignIn">
          <input type="text" id="username" v-model="username" required placeholder=" ">
          <label for="username">사용자 이름</label>
        </div>
        <div class="input-group">
          <input type="text" id="email" v-model="email" required placeholder=" ">
          <label for="text">아이디</label>
        </div>
        <div class="input-group">
          <input type="password" id="password" v-model="password" required placeholder=" ">
          <label for="password">비밀번호</label>
        </div>
        <div class="input-group" v-if="!isSignIn">
          <input type="text" id="wallet" v-model="wallet" required placeholder=" ">
          <label for="wallet">지갑주소</label>
        </div>
        <button type="submit">{{ isSignIn ? '로그인' : '회원가입' }}</button>
      </form>
      <p>
        {{ isSignIn ? "계정이 없으신가요?" : "이미 계정이 있으신가요?" }}
        <a href="#" @click.prevent="toggleForm">
          {{ isSignIn ? '회원가입' : '로그인' }}
        </a>
      </p>
    </div>
  </div>
</template>

<script setup>
import {ref} from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

const isSignIn = ref(true);
const username = ref('');
const email = ref('');
const password = ref('');
const wallet = ref('');

const toggleForm = () => {
  isSignIn.value = !isSignIn.value;
  username.value = '';
  email.value = '';
  password.value = '';
};

const signIn = () => {
  // 로그인 로직 (서버 인증 등)
  console.log('로그인:', email.value, password.value);

  // 로그인 성공 가정
  localStorage.setItem('logIn', 'Y');

  // index 페이지로 이동
  router.push('/');
};

const signUp = () => {
  console.log('회원가입:', username.value, email.value, password.value);
};
</script>

<style scoped>
:root {
  --primary-color: #4EA685;
  --secondary-color: #57B894;
  --background-color: #f0f2f5;
  --text-color: #333;
  --input-color: #fff;
}

.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: calc(100vh - 120px);
  background-color: var(--background-color);
}

.login-box {
  background-color: var(--input-color);
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 15px 35px rgba(0, 0, 0, 0.2);
  width: 100%;
  max-width: 400px;
  transition: transform 0.6s, opacity 0.3s;
}

.login-box:hover {
  box-shadow: 0 25px 45px rgba(0, 0, 0, 0.3);
}

.login-box.sign-up {
  transform: translateX(0);
  opacity: 1;
}

h2 {
  text-align: center;
  color: var(--primary-color);
  margin-bottom: 1.5rem;
  font-size: 2rem;
  text-transform: uppercase;
}

.input-group {
  position: relative;
  margin-bottom: 1.5rem;
}

label {
  position: absolute;
  top: 0.8rem;
  left: 0.5rem;
  color: #999;
  font-size: 1rem;
  pointer-events: none;
  transition: 0.2s ease-out all;
}

input {
  width: 100%;
  padding: 0.8rem 0.5rem;
  border: none;
  border-bottom: 2px solid #ddd;
  background-color: transparent;
  font-size: 1rem;
  transition: 0.2s ease-out all;
  color: white;
}
input::placeholder {
  color: #999; /* placeholder 색상 변경 */
}
input:focus {
  outline: none;
  border-bottom-color: var(--primary-color);
}

input:focus + label,
input:not(:placeholder-shown) + label {
  font-size: 0.8rem;
  transform: translateY(-1.5rem);
  color: var(--primary-color);
}

button {
  width: 100%;
  padding: 0.75rem;
  background-color: var(--primary-color);
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s;
  text-transform: uppercase;
  letter-spacing: 1px;
}

button:hover {
  background-color: var(--secondary-color);
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
  transform: translateY(-2px);
}

p {
  text-align: center;
  margin-top: 1rem;
  color: var(--text-color);
}

a {
  color: var(--primary-color);
  text-decoration: none;
  font-weight: bold;
  transition: color 0.3s;
}

a:hover {
  color: var(--secondary-color);
}

.login-box form {
  transition: opacity 0.3s, transform 0.3s;
}

.login-box.sign-up form {
  opacity: 1;
  transform: translateX(0);
}
</style>