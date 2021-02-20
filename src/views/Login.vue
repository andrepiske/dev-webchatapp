<template lang="html">
  <div class="">

    <div class="">
      <label for="">Username:</label>

      <input type="text" v-model="username">
    </div>

    <div class="">
      <label for="">Password:</label>

      <input type="password" v-model="password">
    </div>

    <button @click="performLogin">Login!</button>
  </div>
</template>

<script>
import { EventBus } from '../EventBus.js';

export default {
  data() {
    return {
      username: 'alice',
      password: 'sekret',
    }
  },

  methods: {
    performLogin() {

      fetch("/perform_login", {
        method: "POST",
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          username: this.username,
          password: this.password
        })
      }).then((response) => {
        response.json().then((jsonBody) => {
          if (jsonBody.status === "login_success") {
            let userFullName = jsonBody.full_name;

            EventBus.$emit('user-logged-in', jsonBody);

          } else if (jsonBody.status === "login_failed") {
            let failureMessage = jsonBody.message;
            alert(`Login failed.\n${failureMessage}`);
          } else {
            alert("System error, try again later");
          }
        });
      });

    }
  }

}
</script>
