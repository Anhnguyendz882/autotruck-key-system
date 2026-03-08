const { Client, GatewayIntentBits } = require("discord.js")
const fs = require("fs")

const client = new Client({
 intents: [
  GatewayIntentBits.Guilds,
  GatewayIntentBits.GuildMessages,
  GatewayIntentBits.MessageContent
 ]
})

function createKey(){

 const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
 let key = "KEY-"

 for(let i=0;i<10;i++){
  key += chars[Math.floor(Math.random()*chars.length)]
 }

 return key
}

client.once("ready",()=>{
 console.log("BOT ONLINE: "+client.user.tag)
})

client.on("messageCreate",msg=>{

 if(msg.author.bot) return

 if(msg.content === ".taokey"){

  let keys=[]

  if(fs.existsSync("keys.json")){
   keys = JSON.parse(fs.readFileSync("keys.json"))
  }

  const newKey = createKey()

  keys.push(newKey)

  fs.writeFileSync("keys.json",JSON.stringify(keys,null,2))

  msg.reply("🔑 Key mới: "+newKey)

 }

})

client.login(process.env.DISCORD_TOKEN)
