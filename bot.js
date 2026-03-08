const { Client, GatewayIntentBits } = require("discord.js")
const fs = require("fs")

const client = new Client({
 intents: [
  GatewayIntentBits.Guilds,
  GatewayIntentBits.GuildMessages,
  GatewayIntentBits.MessageContent
 ]
})

const PREFIX = "."

function generateKey(name){
 const random = Math.random().toString(36).substring(2,10).toUpperCase()
 const time = Date.now().toString().slice(-4)
 return `KEY-${name}-${random}-${time}`
}

client.once("ready",()=>{
 console.log("🤖 Bot online")
})

client.on("messageCreate",(msg)=>{

 if(msg.author.bot) return
 if(!msg.content.startsWith(PREFIX)) return

 const args = msg.content.slice(PREFIX.length).trim().split(/ +/)
 const cmd = args.shift().toLowerCase()

 if(cmd === "taokey"){

  const name = args[0]

  if(!name){
   msg.reply("❌ dùng: .taokey ten_key")
   return
  }

  const key = generateKey(name)

  let data = []

  if(fs.existsSync("keys.json")){
   data = JSON.parse(fs.readFileSync("keys.json"))
  }

  data.push({
   name:name,
   key:key,
   created:Date.now(),
   expire:"never"
  })

  fs.writeFileSync("keys.json",JSON.stringify(data,null,2))

  msg.reply(`✅ Key tạo thành công:\n\`${key}\``)

 }

})

client.login(process.env.DISCORD_TOKEN)
