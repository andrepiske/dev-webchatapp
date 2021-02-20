<template>
  <div>

    <App :user="userDetails" v-if="userIsLoggedIn"></App>
    <Login v-else></Login>

  </div>
</template>

<script>
import App from './App.vue';
import Login from './Login.vue';
import { EventBus } from '../EventBus.js';

export default {
  data() {
    return {
      userIsLoggedIn: false,
      userDetails: null
    }
  },

  created() {
    this.checkUserLoginState();

    EventBus.$on('user-logged-in', (payload) => {
      window.localStorage.setItem('user-api-token', payload.token);
      window.localStorage.setItem('user-details', JSON.stringify(payload));

      this.userDetails = payload;
      this.userIsLoggedIn = true;
    });
  },

  methods: {
    checkUserLoginState() {
      let token = window.localStorage.getItem('user-api-token');
      let userDetails = window.localStorage.getItem('user-details');

      if (token) {
        this.userDetails = JSON.parse(userDetails);
        this.userIsLoggedIn = true;
      }
    }

  },

  components: {
    App,
    Login
  }
}
</script>

<style lang="css" scoped>
</style>
