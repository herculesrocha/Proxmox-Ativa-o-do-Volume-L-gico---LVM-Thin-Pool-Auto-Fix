#!/bin/bash

#############################################################
# Proxmox LVM Thin Pool Auto Recovery
#
# Objetivo:
# Corrigir automaticamente erro de ativação do volume pve/data
# quando os metadados do thin pool permanecem ativos.
#
# Este erro normalmente ocorre após:
# - queda de energia
# - reboot inesperado
# - interrupção durante ativação do LVM
#
# O problema acontece quando:
# pve/data_tmeta permanece ativo enquanto pve/data está inativo.
#
# O script verifica o estado do volume lógico e,
# somente se necessário, executa o procedimento de recuperação.
#
# Autor: Hercules Rocha
#############################################################

LOGTAG="proxmox-lvm-fix"

echo "[$LOGTAG] Iniciando verificação do estado do LVM..."

#############################################################
# Aguarda o udev terminar a criação dos dispositivos
#
# Durante o boot do Linux os dispositivos de bloco podem
# ainda estar sendo detectados. Executar comandos LVM
# antes desse processo terminar pode gerar falhas.
#############################################################

echo "[$LOGTAG] Aguardando inicialização completa dos dispositivos..."

udevadm settle

#############################################################
# Pequeno delay adicional para garantir que o LVM
# finalize o scan dos volumes físicos e grupos de volume.
#############################################################

sleep 5

#############################################################
# Verifica o estado do volume lógico pve/data
#
# O comando abaixo retorna:
# active   -> volume ativo
# inactive -> volume não ativado
#############################################################

LV_STATE=$(lvs --noheadings -o lv_active /dev/pve/data 2>/dev/null | tr -d ' ')

#############################################################
# Caso o volume não esteja ativo, inicia o processo
# de recuperação do Thin Pool.
#############################################################

if [ "$LV_STATE" != "active" ]; then

    echo "[$LOGTAG] Volume lógico pve/data não está ativo."
    echo "[$LOGTAG] Iniciando tentativa de recuperação do Thin Pool..."

    #########################################################
    # Desativa o volume de dados do thin pool
    #
    # Isso evita conflito com o volume principal durante
    # a reativação do storage.
    #########################################################

    echo "[$LOGTAG] Desativando pve/data_tdata..."

    lvchange -an pve/data_tdata 2>/dev/null

    #########################################################
    # Desativa os metadados do thin pool
    #
    # Esse passo remove o bloqueio que impede
    # a ativação do volume principal.
    #########################################################

    echo "[$LOGTAG] Desativando pve/data_tmeta..."

    lvchange -an pve/data_tmeta 2>/dev/null

    #########################################################
    # Ativa novamente o volume principal do thin pool
    #
    # Dependendo do estado do LVM, esse processo pode
    # levar alguns segundos para finalizar.
    #########################################################

    echo "[$LOGTAG] Ativando volume pve/data..."

    lvchange -ay pve/data

    #########################################################
    # Aguarda até 30 segundos pela ativação completa
    # do volume lógico.
    #
    # O script verifica a cada segundo se o volume
    # já está ativo.
    #########################################################

    echo "[$LOGTAG] Aguardando ativação completa do volume..."

    for i in {1..30}; do

        sleep 1

        LV_STATE=$(lvs --noheadings -o lv_active /dev/pve/data 2>/dev/null | tr -d ' ')

        if [ "$LV_STATE" = "active" ]; then

            echo "[$LOGTAG] Volume pve/data ativado com sucesso."

            exit 0

        fi

    done

    #########################################################
    # Caso o volume não tenha sido ativado após o tempo
    # de espera, registra falha no log.
    #########################################################

    echo "[$LOGTAG] Falha ao ativar pve/data após 30 segundos."

    exit 1

else

    #########################################################
    # Caso o volume já esteja ativo, nenhuma ação é necessária.
    #########################################################

    echo "[$LOGTAG] Volume pve/data já está ativo. Nenhuma ação necessária."

fi

exit 0
