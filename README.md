# Proxmox LVM Thin Pool Auto Fix

Runbook técnico para diagnóstico e correção automática do erro de ativação do volume lógico **pve/data** em ambientes **Proxmox VE**.

Este repositório documenta:

* Diagnóstico do problema
* Procedimento de correção manual
* Automação da correção durante o boot do servidor
* Validação pós-correção

O objetivo é evitar falha na inicialização de máquinas virtuais quando o **Thin Pool LVM** entra em estado inconsistente após reboot ou queda inesperada.

---

# Problema

Ao iniciar o servidor **Proxmox**, ao tentar iniciar uma VM ocorre o erro:

```
TASK ERROR: activating LV 'pve/data' failed:
Activation of logical volume pve/data is prohibited
while logical volume pve/data_tmeta is active
```

Sintomas adicionais:

* Storage **local-lvm** aparece com **? (interrogação)** na interface web
* VMs configuradas com **Start at boot** não iniciam
* Thin Pool `pve/data` não ativa corretamente

---

# Causa

O erro ocorre quando o **Thin Pool LVM** permanece parcialmente ativo após:

* queda de energia (No meu caso)
* reboot inesperado
* interrupção do serviço LVM
* inconsistência durante inicialização do storage

Nesse cenário:

* `pve/data_tmeta` permanece ativo
* `pve/data` não pode ser ativado

---

# Solução

Desativar os metadados do Thin Pool e ativar novamente o volume principal.

Correção manual:

```
lvchange -an pve/data_tdata
lvchange -an pve/data_tmeta
lvchange -ay pve/data
```

Este repositório implementa **uma solução automatizada** que executa essa correção **somente quando necessário durante o boot**.

---

# Estrutura do Runbook

| Documento                    | Descrição                              |
| ---------------------------- | -------------------------------------- |
| 01-contexto-do-problema.md   | Explicação técnica do erro             |
| 02-diagnostico.md            | Comandos para análise do estado do LVM |
| 03-correcao-manual.md        | Procedimento manual                    |
| 04-automacao-da-correcao.md  | Configuração de correção automática    |
| 05-validacao-pos-correcao.md | Verificação após correção              |

---

# Script de correção automática

O script principal encontra-se em:

```
scripts/proxmox-lvm-fix.sh
```

Ele:

1. Verifica o estado do LV `pve/data`
2. Executa correção apenas se necessário
3. Permite inicialização correta das VMs

---

# Ambiente testado

* Proxmox VE 7.x
* LVM Thin Pool
* Storage local-lvm
* Servidor **Dell PowerEdge R720**

---

# Licença

Uso livre para ambientes de infraestrutura e administração de sistemas.

---

# Autor
Hercules Rocha

Runbook criado para operações de administração em ambientes Proxmox.
