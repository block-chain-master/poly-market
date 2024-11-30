import { ref, computed } from 'vue';

const isLoggedIn = ref(false);

export function useAuthStore() {
    const getIsLoggedIn = computed(() => isLoggedIn.value);

    function login() {
        isLoggedIn.value = true;
    }

    function logout() {
        isLoggedIn.value = false;
    }

    function checkLoginStatus() {
        return isLoggedIn.value;
    }

    return {
        isLoggedIn: getIsLoggedIn,
        login,
        logout,
        checkLoginStatus
    };
}