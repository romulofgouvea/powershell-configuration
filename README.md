# Configure PowerShell 7

Configuração completa do profile do PowerShell em **um passo**: clone e execute.

## Instalação

```powershell
git clone https://github.com/romulofgouvea/power-shell-profile.git
cd power-shell-profile
.\Install.ps1
```

Se a política de execução bloquear o `.ps1`, dê **duplo-clique no `install.bat`** (ou rode `.\install.bat`) — ele ignora a política só nessa chamada.

Depois, feche e abra o PowerShell 7. Pronto, mais nada.

## PowerShell 7

Você **não precisa** instalar o PowerShell 7 antes. O `Install.ps1` cuida disso:

- Se você rodar no **Windows PowerShell 5.1** (o azul que já vem no Windows), o script
  detecta e **se re-executa sozinho no PowerShell 7**.
- Se o **PowerShell 7 não estiver instalado**, ele instala via `winget`
  (`winget install --id Microsoft.PowerShell`) e continua a instalação nele.
- Se a máquina **não tiver `winget`** (raro no Windows 10/11 atual), o script para e
  pede para você instalar o PowerShell 7 manualmente por <https://aka.ms/powershell>
  e rodar de novo.

O profile é configurado no `$PROFILE` do **PowerShell 7** — o Windows PowerShell 5.1
não é alterado.

## O que o `Install.ps1` faz

- **Instala o PowerShell 7** (via `winget`) se você ainda não tiver, e continua nele
  (detalhes na seção acima)
- Libera a execução de scripts para o usuário atual (`RemoteSigned`)
- Marca a PSGallery como confiável e instala os módulos: `posh-git`, `PSReadLine`, `Terminal-Icons`
- Instala o `oh-my-posh` (use `.\Install.ps1 -NoOhMyPosh` para pular)
- Faz **backup** do seu `$PROFILE` atual e faz ele carregar o `profile.ps1` deste repositório

Para atualizar depois, dentro da pasta:

```powershell
git pull
```

> **Não mova nem apague esta pasta** depois de instalar — o `$PROFILE` aponta para o `profile.ps1` dela.

## O que o `profile.ps1` configura

- Importa os módulos instalados
- Autocomplete com `Tab`, busca no histórico com as setas, sugestões preditivas
- Prompt do `oh-my-posh`
- `ls` colorido estilo Unix (`Scripts/powerls.psm1`)
- Atalhos: `..`, `...`, `gs`, `gp`, `which`
- Abre em `D:\workspace` (se existir)

## Dica

Para os ícones aparecerem certos, use uma **Nerd Font** no seu terminal
(ex: `winget install DEVCOM.JetBrainsMonoNerdFont` e selecione no Windows Terminal).
