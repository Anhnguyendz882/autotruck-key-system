const { Client, GatewayIntentBits } = require("discord.js")
const fs = require("fs")

const TOKEN = process.env.TOKEN

const client = new Client({
  intents:[
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
})

const KEY_FILE = "./keys.json"

if(!fs.existsSync(KEY_FILE)){
  fs.writeFileSync(KEY_FILE, JSON.stringify({}))
}

function loadKeys(){
  return JSON.parse(fs.readFileSync(KEY_FILE))
}

function saveKeys(data){
  fs.writeFileSync(KEY_FILE, JSON.stringify(data,null,2))
}

function generateKey(){
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  let key = ""
  for(let i=0;i<32;i++){
    key += chars.charAt(Math.floor(Math.random()*chars.length))
  }
  return key
}

client.once("ready", ()=>{
  console.log("BOT ONLINE:", client.user.tag)
})

client.on("messageCreate", async (msg)=>{
  if(msg.author.bot) return

  const args = msg.content.split(" ")

  if(args[0] === ".taokey"){

    const ingame = args[1]

    if(!ingame){
      msg.reply("❌ dùng: `.taokey ten_ingame`")
      return
    }

    const keys = loadKeys()

    const key = generateKey()

    keys[key] = {
      ingame: ingame,
      discord: msg.author.id,
      created: Date.now()
    }

    saveKeys(keys)

    msg.reply(`✅ Key của **${ingame}**

\`\`\`
${key}
\`\`\`
`)
  }

})

client.login(TOKEN)
