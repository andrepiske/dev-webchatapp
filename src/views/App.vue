<template lang="html">
  <div>

    <h1>Chat application</h1>

    <div class="application_container">

      <div class="user_name__container">
        User name: {{ user.full_name }}
      </div>

      <div class="chat_text__container">
        <div class="chat_text__message__wrapper" v-for="message in messages">
          <div class="chat_text__message__user_name">{{ message.userName }}</div>
          <div class="chat_text__message__text">{{ message.messageContent }}</div>
          <div class="chat_text__message__timestamp">{{ formatMessageTime(message) }}</div>
        </div>
      </div>

      <div class="message_input_container">
        <input type="text" v-model="messageContent">
        <button @click="onSendClick">Send</button>
      </div>
    </div>

  </div>
</template>

<script>
import dateFormat from 'dateformat';

export default {
  data() {
    return {
      latestCursor: 0,
      messageContent: '',
      messages: [],
    }
  },

  props: [
    'user'
  ],

  methods: {
    formatMessageTime(message) {
      const d = new Date(message.timestamp);
      return dateFormat(d, 'dd/mm HH:MM');
    },

    checkNewMessages() {
      fetch(`/poll_messages/${this.latestCursor}`, {
        method: 'GET',
        cache: 'no-cache',
        headers: {
          'Accept': 'application/json'
        },
      }).then((response) => {
        response.json().then((content) => {
          this.processMessagesResponse(content);
        });
      });
    },

    processMessagesResponse(messages) {
      for (let msg of messages) {
        this.insertMessageInScreen(msg);

        let messageTime = new Date(msg.current_time).getTime() / 1000;
        if (messageTime > this.latestCursor) {
          this.latestCursor = messageTime;
        }
      }
    },

    insertMessageInScreen(msg) {
      this.messages.push({
        userName: msg.user_name,
        messageContent: msg.message_content,
        timestamp: msg.current_time
      });
    },

    onSendClick() {
      fetch("/send_message", {
        method: "POST",
        headers: {
          'Content-Type': 'application/json',
          'Api-Token': this.user.token,
        },
        body: JSON.stringify({
          message_content: this.messageContent
        })
      }).then((response) => {
        if (response.status !== 204) {
          alert("PANIC! Message could not be sent.");
        } else {
          this.messageContent = '';
        }
      }).catch(() => {
        alert("PANIC! Request failed.");
      });
    },

  },

  mounted() {
    this.checkNewMessages();

    setInterval(() => {
      // console.log("Checking for new messages...");
      this.checkNewMessages();
    }, 1000);
  }
}
</script>
