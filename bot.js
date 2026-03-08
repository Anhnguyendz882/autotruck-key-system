const { Client, GatewayIntentBits } = require("discord.js")
const fs = require("fs")

console.log("Starting Discord bot...")

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
})

const TOKEN = process.env.DISCORD_TOKEN

if (!TOKEN) {
  console.log("❌ DISCORD_TOKEN not found in environment variables")
  process.exit(1)
}

const KEY_FILE = "./keys.json"

if (!fs.existsSync(KEY_FILE)) {
  fs.writeFileSync(KEY_FILE, "{}")
}

function generateKey(){
  return "KEY-" + Math.random().toString(36).substring(2,10).toUpperCase()
}

client.once("ready", () => {
  console.log(`🤖 BOT ONLINE: ${client.user.tag}`)
})

client.on("error", (err)=>{
  console.log("Discord client error:", err)
})

client.on("messageCreate", (msg) => {
  if (msg.author.bot) return

  if (msg.content.startsWith(".taokey")) {
    const args = msg.content.split(" ")
    const ingame = args[1]

    if (!ingame) {
      return msg.reply("❌ dùng: .taokey ingame")
    }

    const key = generateKey()

    const keys = JSON.parse(fs.readFileSync(KEY_FILE))
    keys[key] = { ingame: ingame }

    fs.writeFileSync(KEY_FILE, JSON.stringify(keys, null, 2))

    msg.reply(`✅ KEY CREATED\n\nKEY: \`${key}\`\nINGAME: \`${ingame}\``)
  }
})

client.login(TOKEN)
.then(()=>{
  console.log("Discord login success")
})
.catch(err=>{
  console.log("❌ Discord login error:", err.message)
})
