﻿unit TelegAPI.Base;

interface

uses
  System.Classes;

type
  TtgAbstractComponent = class(TComponent)
  private
    FVersion: string;
    FAutor: string;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Autor: string read FAutor;
    /// <summary>
    ///   Поддерживаемая версия платформы BotAPI
    /// </summary>
    property Version: string read FVersion;
  end;

implementation

{ TtgAbstractComponent }

constructor TtgAbstractComponent.Create(AOwner: TComponent);
begin
  inherited;
  FAutor := 'Maxim Sysoev';
  FVersion := '3.5.1';
end;

end.

