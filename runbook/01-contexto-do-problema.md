# Contexto do Problema

Em ambientes **Proxmox**, o storage `local-lvm` utiliza **LVM Thin Pool** para armazenamento das máquinas virtuais.

Estrutura típica:

```
VG: pve
LV: pve/data
Thin Pool: pve/data_tmeta
Thin Pool: pve/data_tdata
```

Durante uma inicialização anormal do sistema, os metadados do Thin Pool podem permanecer ativos enquanto o volume principal permanece desativado.

Isso impede a ativação do volume `pve/data`.

Erro exibido:

```
Activation of logical volume pve/data is prohibited
while logical volume pve/data_tmeta is active
```

Consequências:

* Storage local-lvm inacessível
* VMs não iniciam
* interface do Proxmox mostra storage com erro
