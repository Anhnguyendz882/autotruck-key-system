const { Client, GatewayIntentBits } = require("discord.js")

console.log("Starting Discord bot...")

const TOKEN = process.env.DISCORD_TOKEN

if (!TOKEN) {
  console.log("❌ DISCORD_TOKEN not found")
}

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
})

client.once("ready", () => {
  console.log("🤖 BOT ONLINE:", client.user.tag)
})

client.login(TOKEN)
.then(() => {
  console.log("Discord login success")
})
.catch(err => {
  console.log("❌ Discord login error:", err)
})
