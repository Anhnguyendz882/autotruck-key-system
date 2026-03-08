const { Client, GatewayIntentBits, EmbedBuilder } = require("discord.js")
const fs = require("fs")

const TOKEN = process.env.DISCORD_TOKEN

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
})

const DB = "keys.json"

if (!fs.existsSync(DB)) {
  fs.writeFileSync(DB, JSON.stringify({}))
}

function loadDB() {
  return JSON.parse(fs.readFileSync(DB))
}

function saveDB(data) {
  fs.writeFileSync(DB, JSON.stringify(data, null, 2))
}

function genKey() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  let key = "AT-"

  for (let i = 0; i < 10; i++) {
    key += chars[Math.floor(Math.random() * chars.length)]
  }

  return key
}

client.once("ready", () => {
  console.log("Bot ready:", client.user.tag)
})

client.on("messageCreate", async (msg) => {

  if (msg.author.bot) return

  const args = msg.content.split(" ")

  if (args[0] === ".taokey") {

    const ingame = args[1]
    const days = parseInt(args[2])

    if (!ingame || !days) {
      return msg.reply("Use: .taokey ingame days")
    }

    const key = genKey()
    const expire = Date.now() + days * 86400000

    const db = loadDB()

    db[key] = {
      user: ingame,
      expire: expire
    }

    saveDB(db)

    msg.reply(`Key created: ${key}`)
  }

  if (args[0] === ".listkey") {

    const db = loadDB()

    const embed = new EmbedBuilder()
      .setTitle("Key List")
      .setColor(0x00ff00)

    for (const key in db) {

      const user = db[key].user
      const expire = new Date(db[key].expire).toLocaleDateString()

      embed.addFields({
        name: key,
        value: `User: ${user}\nExpire: ${expire}`
      })
    }

    msg.reply({ embeds: [embed] })
  }

  if (args[0] === ".delkey") {

    const ingame = args[1]

    const db = loadDB()

    for (const key in db) {
      if (db[key].user === ingame) {
        delete db[key]
      }
    }

    saveDB(db)

    msg.reply("Key removed")
  }

})

client.login(TOKEN)
