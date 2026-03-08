const { Client, GatewayIntentBits } = require("discord.js")
const fs = require("fs")

console.log("Starting Discord bot...")

const TOKEN = process.env.DISCORD_TOKEN

if (!TOKEN) {
  console.log("❌ DISCORD_TOKEN not found")
  process.exit(1)
}

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
})

const DB_FILE = "keys.json"

if (!fs.existsSync(DB_FILE)) {
  fs.writeFileSync(DB_FILE, JSON.stringify({}))
}

function generateKey() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  let key = "AT-"
  for (let i = 0; i < 10; i++) {
    key += chars[Math.floor(Math.random() * chars.length)]
  }
  return key
}

client.once("ready", () => {
  console.log("Discord login success")
  console.log("🤖 BOT ONLINE:", client.user.tag)
})

client.on("messageCreate", async (message) => {

  if (message.author.bot) return

  if (message.content.startsWith(".taokey")) {

    const args = message.content.split(" ")

    if (args.length < 2) {
      return message.reply("❌ dùng: `.taokey ten_ingame`")
    }

    const ingame = args[1]

    const key = generateKey()

    const data = JSON.parse(fs.readFileSync(DB_FILE))

    data[key] = {
      user: ingame
    }

    fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2))

    message.reply(
`✅ KEY CREATED

Ingame: ${ingame}
Key: ${key}`
    )
  }

})

client.login(TOKEN)
.catch(err => {
  console.log("❌ LOGIN ERROR:", err)
})
