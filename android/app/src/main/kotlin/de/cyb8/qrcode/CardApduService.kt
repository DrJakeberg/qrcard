package de.cyb8.qrcode

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.ByteArrayOutputStream

/**
 * Gibt die Visitenkarte per NFC aus, wenn ein anderes Geraet angetippt wird.
 *
 * Das Telefon verhaelt sich dabei wie ein NFC-Tag nach "NFC Forum Type 4":
 * Das lesende Geraet waehlt erst die NDEF-Anwendung, dann die Dateien aus und
 * liest sie haeppchenweise. Genau diesen Ablauf bildet diese Klasse nach.
 *
 * Der vCard-Text kommt aus demselben Speicher, den auch das Homescreen-Widget
 * nutzt - so gibt es nur eine Quelle fuer die Kartendaten.
 */
class CardApduService : HostApduService() {

    /** Die aktuell ausgelieferte Datei (CC oder NDEF). */
    private var selectedFile: SelectedFile = SelectedFile.NONE

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null || commandApdu.size < 4) return STATUS_FAILED

        // SELECT nach Namen: die NDEF-Anwendung.
        if (commandApdu.startsWithBytes(SELECT_NDEF_APPLICATION)) {
            selectedFile = SelectedFile.NONE
            return STATUS_SUCCESS
        }

        // SELECT nach Datei-ID: Capability Container oder NDEF-Datei.
        if (commandApdu.startsWithBytes(SELECT_FILE_PREFIX) && commandApdu.size >= 7) {
            val fileId = commandApdu.copyOfRange(5, 7)
            selectedFile = when {
                fileId.contentEquals(CC_FILE_ID) -> SelectedFile.CAPABILITY_CONTAINER
                fileId.contentEquals(NDEF_FILE_ID) -> SelectedFile.NDEF
                else -> return STATUS_FILE_NOT_FOUND
            }
            return STATUS_SUCCESS
        }

        // READ BINARY: den gewaehlten Abschnitt der Datei liefern.
        if (commandApdu.size >= 5 && commandApdu[0] == 0x00.toByte() &&
            commandApdu[1] == 0xB0.toByte()
        ) {
            val offset = ((commandApdu[2].toInt() and 0xFF) shl 8) or
                (commandApdu[3].toInt() and 0xFF)
            val length = commandApdu[4].toInt() and 0xFF

            val file = when (selectedFile) {
                SelectedFile.CAPABILITY_CONTAINER -> capabilityContainer()
                SelectedFile.NDEF -> ndefFile()
                SelectedFile.NONE -> return STATUS_FILE_NOT_FOUND
            }

            if (offset > file.size) return STATUS_FAILED
            val end = minOf(offset + length, file.size)
            return file.copyOfRange(offset, end) + STATUS_SUCCESS
        }

        return STATUS_FAILED
    }

    override fun onDeactivated(reason: Int) {
        selectedFile = SelectedFile.NONE
    }

    /**
     * Beschreibt dem Lesegeraet, wo die NDEF-Datei liegt und wie gross sie
     * werden darf. Schreibzugriff ist ausgeschlossen (0xFF).
     */
    private fun capabilityContainer(): ByteArray = byteArrayOf(
        0x00, 0x0F,             // Laenge dieser Datei: 15 Byte
        0x20,                   // Version 2.0
        0x00, 0x3B,             // groesste Antwort, die wir senden
        0x00, 0x34,             // groesstes Kommando, das wir annehmen
        0x04, 0x06,             // TLV: NDEF-Datei, 6 Byte Beschreibung
        0xE1.toByte(), 0x04,    // Datei-ID der NDEF-Datei
        0x7F, 0xFF.toByte(),    // Maximalgroesse
        0x00,                   // lesen erlaubt
        0xFF.toByte(),          // schreiben nicht erlaubt
    )

    /** Zwei Byte Laenge, dann die NDEF-Nachricht mit der vCard. */
    private fun ndefFile(): ByteArray {
        val message = ndefMessage(readVCard())
        return byteArrayOf(
            ((message.size shr 8) and 0xFF).toByte(),
            (message.size and 0xFF).toByte(),
        ) + message
    }

    /** Liest die vCard aus dem geteilten Speicher der App. */
    private fun readVCard(): String {
        val stored = HomeWidgetPlugin.getData(this).getString(KEY_VCARD, null)
        return if (stored.isNullOrBlank()) EMPTY_VCARD else stored
    }

    /**
     * Baut eine NDEF-Nachricht mit genau einem MIME-Datensatz "text/vcard".
     *
     * Bis 255 Byte darf das kurze Format verwendet werden, darueber muss die
     * Laenge mit vier Byte angegeben werden - eine vCard liegt meist darueber.
     */
    private fun ndefMessage(vcard: String): ByteArray {
        val payload = vcard.toByteArray(Charsets.UTF_8)
        val type = MIME_TYPE.toByteArray(Charsets.US_ASCII)
        val short = payload.size < 256

        val out = ByteArrayOutputStream()
        // MB + ME gesetzt (einziger Datensatz), TNF = 2 (MIME).
        out.write(if (short) 0xD2 else 0xC2)
        out.write(type.size)
        if (short) {
            out.write(payload.size)
        } else {
            out.write((payload.size shr 24) and 0xFF)
            out.write((payload.size shr 16) and 0xFF)
            out.write((payload.size shr 8) and 0xFF)
            out.write(payload.size and 0xFF)
        }
        out.write(type)
        out.write(payload)
        return out.toByteArray()
    }

    private fun ByteArray.startsWithBytes(prefix: ByteArray): Boolean {
        if (size < prefix.size) return false
        for (i in prefix.indices) {
            if (this[i] != prefix[i]) return false
        }
        return true
    }

    private enum class SelectedFile { NONE, CAPABILITY_CONTAINER, NDEF }

    private companion object {
        /** Muss zu WidgetBridge in lib/services/widget_bridge.dart passen. */
        const val KEY_VCARD = "card_vcard"

        const val MIME_TYPE = "text/vcard"

        /** SELECT der NDEF-Anwendung (AID D2760000850101). */
        val SELECT_NDEF_APPLICATION = byteArrayOf(
            0x00, 0xA4.toByte(), 0x04, 0x00, 0x07,
            0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01,
        )

        /** SELECT einer Datei ueber ihre ID. */
        val SELECT_FILE_PREFIX = byteArrayOf(0x00, 0xA4.toByte(), 0x00, 0x0C, 0x02)

        val CC_FILE_ID = byteArrayOf(0xE1.toByte(), 0x03)
        val NDEF_FILE_ID = byteArrayOf(0xE1.toByte(), 0x04)

        val STATUS_SUCCESS = byteArrayOf(0x90.toByte(), 0x00)
        val STATUS_FILE_NOT_FOUND = byteArrayOf(0x6A, 0x82.toByte())
        val STATUS_FAILED = byteArrayOf(0x6F, 0x00)

        /** Fallback, solange noch keine Karte gespeichert wurde. */
        const val EMPTY_VCARD = "BEGIN:VCARD\r\nVERSION:3.0\r\nFN:\r\nEND:VCARD"
    }
}
