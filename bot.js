const { Client, GatewayIntentBits } = require("discord.js")
const fs = require("fs")

// lấy token từ Render ENV
const TOKEN = process.env.DISCORD_TOKEN

if(!TOKEN){
  console.log("❌ DISCORD_TOKEN not found in environment variables")
  process.exit(1)
}

const client = new Client({
  intents:[
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
})

const KEY_FILE = "./keys.json"

// tạo file nếu chưa có
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
  console.log("🤖 BOT ONLINE:", client.user.tag)
})

client.on("messageCreate",(msg)=>{

  if(msg.author.bot) return

  const args = msg.content.trim().split(" ")

  // tạo key
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

    msg.reply(`✅ Key cho **${ingame}**

\`\`\`
${key}
\`\`\`
`)
  }

  // check key
  if(args[0] === ".checkkey"){

    const key = args[1]

    if(!key){
      msg.reply("❌ dùng: `.checkkey key`")
      return
    }

    const keys = loadKeys()

    if(keys[key]){
      msg.reply(`✅ Key hợp lệ

Ingame: ${keys[key].ingame}`)
    }else{
      msg.reply("❌ Key không tồn tại")
    }
  }

  // xoá key
  if(args[0] === ".delkey"){

    const key = args[1]

    const keys = loadKeys()

    if(keys[key]){
      delete keys[key]
      saveKeys(keys)
      msg.reply("🗑️ Key đã bị xóa")
    }else{
      msg.reply("❌ Key không tồn tại")
    }
  }

})

client.login(TOKEN)
