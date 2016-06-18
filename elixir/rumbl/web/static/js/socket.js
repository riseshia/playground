import {Socket} from "phoenix"

let socket = new Socket("/socket", {
  params: {token: window.userToken},
  logger: (king, msg, data) => { console.log(`${king}: ${msg}`, data) }
})

export default socket
