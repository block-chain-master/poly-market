<template>
  <header class="gnb">
    <div class="gnb-container">
      <div class="logo">
        <NuxtLink to="/">
          <img src="https://dynamic.design.com/preview/logodraft/d4ea85e2-d297-4709-a83c-be65a42ba465/image/large.png" alt="Logo" class="logo-image">
        </NuxtLink>
      </div>
      <nav class="nav-menu">
        <ul>
          <li>
            <NuxtLink to="/" class="nav-link">홈</NuxtLink>
          </li>
          <li>
            <template v-if="!isLogin">
              <NuxtLink to="/login" class="nav-link">로그인</NuxtLink>
            </template>
            <template v-else>
              <NuxtLink v-if="isLogin" to="#" class="nav-link" @click.prevent="logout">로그아웃</NuxtLink>
            </template>
          </li>
          <li>
            <NuxtLink to="/wallet/wallet" class="nav-link">지갑</NuxtLink>
          </li>
        </ul>
      </nav>
    </div>
  </header>
</template>

<script setup>

import {useAuthStore} from "~/storage/auth.js";

const authStore = useAuthStore()

const isLogin = authStore.isLoggedIn;

const logout = () => {
  authStore.logout()
  window.location.reload()
}
</script>

<style scoped>
.gnb {
  background-color: var(--colors-shadeWhite, #1D2B39);
  color: var(--colors-shadeBlack, #ffffff);
  height: 64px;
  width: 100%;
  z-index: 6;
}

.gnb-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
}

.logo {
  display: flex;
  align-items: center;
}

.logo-image {
  height: 35px;
  width: auto;
}

.nav-menu ul {
  display: flex;
  list-style-type: none;
  margin: 0;
  padding: 0;
}

.nav-menu li {
  margin-left: 20px;
}

.nav-link {
  color: var(--colors-shadeBlack, #ffffff);
  text-decoration: none;
  font-size: 16px;
  font-weight: 500;
  transition: color 0.2s ease;
}

.nav-link:hover {
  color: var(--colors-polyBlue, #2D9CDB);
}
</style>