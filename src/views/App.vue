<template lang="html">
  <div class="chat_container">
    <div class="chat_header">
      <div class="chat_header__title">
        <h1>Ruby chat</h1>
      </div>

      <div class="chat_header__user_name">
        {{ user.full_name }}
      </div>

      <div class="chat_header__user_avatar">
        <img src="/img/empty-avatar.png" alt="No avatar">
      </div>
    </div>

    <div class="chat_text__container">
      <div class="chat_text__message__wrapper" v-for="message in messages">
        <div class="chat_text__message__user_name">{{ message.userName }}</div>
        <div class="chat_text__message__text">{{ message.messageContent }}</div>
        <div class="chat_text__message__timestamp">{{ formatMessageTime(message) }}</div>
      </div>
    </div>

    <div class="chat_container__footer">
      <div class="message_input_container">
        <input class="message_input_container__message" type="text" v-model="messageContent">

        <button class="message_input__send_button" @click="onSendClick">
          <img src="/img/send-icon.png" alt="Send">
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import dateFormat from 'dateformat';

export default {
  data() {
    return {
      channelId: 'start',
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

    pollForNewMessages() {
      this.checkNewMessages().then(() => {
        this.pollForNewMessages();
      });
    },

    checkNewMessages() {
      return new Promise((resolve, reject) => {
        fetch(`/m/poll/${this.channelId}`, {
          method: 'GET',
          cache: 'no-cache',
          headers: {
            'Accept': 'application/json'
          },
        }).then((response) => {
          response.json().then((content) => {
            this.channelId = content.channel_id;
            if (content.message) {
              this.processMessagesResponse([ content.message ]);
            }
            resolve();
          });
        }).catch(resolve);
      });
    },

    fetchArchivedMessages() {
      return new Promise((resolve, reject) => {
        fetch('/m/archived', {
          method: 'GET',
          cache: 'no-cache',
          headers: {
            'Accept': 'application/json'
          },
        }).then((response) => {
          response.json().then((content) => {
            this.processMessagesResponse(content);
            resolve();
          });
        });
      });
    },

    processMessagesResponse(messages) {
      for (let msg of messages) {
        this.insertMessageInScreen(msg);
        // let messageTime = new Date(msg.current_time).getTime() / 1000;
        // if (messageTime > this.latestCursor) {
        //   this.latestCursor = messageTime;
        // }
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
      fetch("/m/send", {
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
    this.fetchArchivedMessages().then(this.pollForNewMessages);
  }
}
</script>
